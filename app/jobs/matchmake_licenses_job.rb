class MatchmakeLicensesJob < ApplicationJob
  queue_as :default

  def perform(hunt, within_between_properties)
    within = within_between_properties[:within]
    between = within_between_properties[:between]
    throw :no_hunt unless hunt
    hunt.rounds.create if hunt.rounds.blank?
    licenses = hunt.licenses.where(eliminated: false)
      .joins(License.sanitize_sql_array(['LEFT OUTER JOIN licenses_matches ON licenses_matches.license_id = 
        licenses.id LEFT OUTER JOIN matches ON matches.id = licenses_matches.match_id AND matches.round_id = ?',
                                         hunt.current_round.id]))
      .where(matches: { id: nil }).distinct
    return if licenses.blank?

    matchmake = Matchmake.new(licenses.includes(:participant), round_id: hunt.current_round.id, within: within, between: between)
    matches = matchmake.matchmake
    matches.save_all

    # Broadcast to action cable
    MatchesChannel.broadcast_to(hunt, {})
  end
end
