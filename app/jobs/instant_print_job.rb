# frozen_string_literal: true

class InstantPrintJob < ApplicationJob
  JAR_LOCATION = 'lib/script/pin-press.jar'

  queue_as :default

  before_enqueue :validate_arguments

  def perform(current_hunt, ordering_params)
    current_round = current_hunt.current_round
    # The ordering_params array has been checked at this point, otherwise this could be pretty dangerous.
    order_cli_args = ordering_params.reduce('') { |total_args, pairing| total_args + " --ordering #{pairing[0]}:#{pairing[1]}" }
    success = system("java -jar #{JAR_LOCATION} #{current_round.id} --template TestForm.pdf --output test.pdf #{order_cli_args}") # TODO arguments
    puts "success: #{success}" # FIXME remove
  end

  private

  def validate_arguments
    current_round = arguments.first.current_round
    ordering_params = arguments.second
    raise ArgumentError, 'Cannot perform Instant Print without a round in the current hunt' if current_round.blank?

    return unless ordering_params.present?

    unless ordering_params.is_a?(Array) && ordering_params.all? { |pairing| pairing.is_a?(Array) && pairing.size == 2 }
      raise ArgumentError, 'Ordering params needs to be an array of tuples of length 2 each.'
    end
  end
end
