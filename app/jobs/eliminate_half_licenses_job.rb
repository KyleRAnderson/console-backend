# Job to eliminate one license at random from every open match.
# This will have the effect of closing all matches in the round.
# Essentially, this does the coin toss for the round.
class EliminateHalfLicensesJob < ApplicationJob
  queue_as :default

  def perform(round)
    licenses_to_update = round.matches.ongoing.map do |match|
      license = match.licenses.sample
      license.eliminated = true
      license
    end
    License.import licenses_to_update,
                   on_duplicate_key_update: { conflict_target: [:id], columns: [:eliminated] }
  end
end
