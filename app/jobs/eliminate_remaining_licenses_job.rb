class EliminateRemainingLicensesJob < ApplicationJob
  queue_as :default

  # Eliminates all licenses that are in open matches.
  def perform(hunt)
    open_matches_ids = hunt.matches.open.select(:id)
    # Joins will only load the licenses that have an associated match
    License
      .joins(:matches)
      .where(matches: { id: open_matches_ids })
      .update_all(eliminated: true)
  end
end
