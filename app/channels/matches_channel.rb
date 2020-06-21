class MatchesChannel < ApplicationCable::Channel
  def subscribed
    hunt = Hunt.find_by(id: params[:hunt_id])
    if HuntPolicy.new(current_user, hunt).show?
      stream_for hunt
    end
  end
end
