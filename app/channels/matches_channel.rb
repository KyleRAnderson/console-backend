class MatchesChannel < ApplicationCable::Channel
  def subscribed
    puts 'Gained one subscriber' # FIXME
    stream_for current_user
  end
end
