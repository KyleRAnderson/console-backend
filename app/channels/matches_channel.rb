class MatchesChannel < ApplicationCable::Channel
  def subscribed
    hunt = Hunt.joins(:roster).find_by(id: params[:hunt_id], rosters: { user_id: current_user.id })
    stream_for hunt
  end
end
