# frozen_string_literal: true

class InstantPrintJob < ApplicationJob
  JAR_LOCATION = 'lib/script/pin-press.jar'

  queue_as :default

  before_enqueue :validate_arguments

  def perform(current_hunt, ordering_params = nil)
    current_round = current_hunt.current_round
    # The ordering_params array has been checked at this point, otherwise this could be pretty dangerous.
    order_cli_args = ordering_params&.reduce('') do |total_args, pairing|
      total_args + " --ordering #{pairing[0]}:#{pairing[1]}"
    end || ''
    temp_file = Tempfile.new('output.pdf')
    begin
      current_hunt.template_pdf.open do |template_pdf|
        system("java -jar #{JAR_LOCATION} #{current_round.id} --template #{template_pdf.path} " \
        "--output #{temp_file.path} #{order_cli_args}")
      end
      # Will purge the existing one if there is one.
      current_hunt.license_printout.attach(io: File.open(temp_file.path), filename: 'printout.pdf', content_type: 'application/pdf')
    ensure
      temp_file.unlink
    end
  end

  private

  def validate_arguments
    current_hunt = arguments.first
    current_round = current_hunt.current_round
    ordering_params = arguments.second
    raise ArgumentError, 'Cannot perform Instant Print without a round in the current hunt' if current_round.blank?

    errors = []

    if ordering_params.present? &&
       (!ordering_params.is_a?(Array) || !ordering_params.all? { |pairing| pairing.is_a?(Array) && pairing.size == 2 })
      errors << 'Ordering params needs to be an array of tuples of length 2 each.'
    end

    unless current_hunt.template_pdf.present?
      errors << 'The given hunt does not have a Template PDF. Please configure one first.'
    end

    raise ArgumentError, errors.join('\n') if errors.present?
  end
end
