class MatchesChannel < ApplicationCable::Channel
  def subscribed
    query = Hunt.joins(roster: :permissions).where(id: params[:hunt_id])
    hunt = query.where(rosters: { owner: current_user })
      .or(query.where(rosters: { permissions: { user: current_user } })).first
    stream_for hunt
  end
end
