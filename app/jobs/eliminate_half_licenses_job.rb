# Job to eliminate one license at random from every open match.
# This will have the effect of closing all matches in the round.
# Essentially, this does the coin toss for the round.
class EliminateHalfLicensesJob < ApplicationJob
  queue_as :default

  def self.eliminate_half(matches)
    license_ids_to_update = matches.map do |match|
      match.licenses.sample.id
    end
    License.where(id: license_ids_to_update).update_all(eliminated: true)
  end

  def perform(round)
    EliminateHalfLicensesJob.eliminate_half(round.matches.ongoing)
  end
end
