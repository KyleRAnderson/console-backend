class MatchmakeLicensesJob < ApplicationJob
  queue_as :default

  def perform(hunt, within_between_properties, user)
    within = within_between_properties[:within]
    between = within_between_properties[:between]
    throw :no_hunt unless hunt
    hunt.rounds.create if hunt.rounds.empty?
    query = hunt.licenses.where(eliminated: false).left_outer_joins(:matches)
    licenses = query.where(matches: { id: nil }).or(query.where.not(matches: { round_id: hunt.current_round.id }))
    matchmake = Matchmake.new(licenses.includes(:participant), round_id: hunt.current_round.id, within: within, between: between)
    matches = matchmake.matchmake
    matches.save_all

    # Broadcast to action cable
    puts "User: #{user.email}" # FIXME
    MatchesChannel.broadcast_to(user, title: 'Done', body: 'Done matchmaking.') # FIXME up
  end
end
