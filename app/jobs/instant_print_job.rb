class InstantPrintJob < ApplicationJob
  JAR_LOCATION = 'lib/script/pin-press.jar'

  queue_as :default

  before_enqueue :validate_arguments

  def perform(current_hunt)
    current_round = current_hunt.current_round
    success = system("java -jar #{JAR_LOCATION} #{current_round.id}")
    puts "success: #{success}" # FIXME remove
  end

  private

  def validate_arguments
    current_round = arguments.first.current_round
    raise ArgumentError, 'Cannot perform Instant Print without a round in the current hunt' if current_round.blank?
  end
end
