class MatchmakeLicensesJob < ApplicationJob
  queue_as :default

  def perform(hunt, within: nil, between: nil)
    licenses = hunt.licenses.where(eliminated: false)
    matchmake = Matchmake.new(licenses, round_id: hunt.current_round.id, within: within, between: between)
    matches = matchmake.matchmake
    Match.transaction do
      matches.each(&:save!)
    end
  end
end
