class MatchmakeLicensesJob < ApplicationJob
  queue_as :default

  def perform(hunt, within: nil, between: nil)
    throw :no_hunt unless hunt
    hunt.rounds.create if hunt.rounds.empty?
    query = hunt.licenses.where(eliminated: false).left_outer_joins(:matches)
    licenses = query.where(matches: { id: nil }).or(query.where.not(matches: { round_id: hunt.current_round.id }))
    matchmake = Matchmake.new(licenses, round_id: hunt.current_round.id, within: within, between: between)
    matches = matchmake.matchmake
    matches.save_all
  end
end
