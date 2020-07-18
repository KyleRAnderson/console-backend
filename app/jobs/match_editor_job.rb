class MatchEditorJob < ApplicationJob
  queue_as :default

  before_enqueue :validate_arguments

  def perform(round, pairings)
    Match.edit_matches(round, pairings)
    # Broadcast to action cable
    MatchesChannel.broadcast_to(round.hunt, {})
  end

  private

  def validate_arguments
    Match.validate_edit_arguments(*arguments)
  end
end
