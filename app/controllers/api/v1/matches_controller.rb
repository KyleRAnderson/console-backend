class Api::V1::MatchesController < ApplicationController
  include Api::V1::Rounds

  before_action :authenticate_user!
  before_action :current_round
  before_action :prepare_match, except: %i[index create]

  def index
    render json: current_round.matches, status: :ok
  end

  def show
    render json: @match, status: :ok
  end

  def create
    match = current_round.matches.build(match_params)
    save_and_render_resource(match)
  end

  def destroy
    destroy_and_render_resource(@match)
  end

  def matchmake
    MatchmakeLicensesJob.perform_later(current_round.hunt, **matchmake_params[:matchmake])
    head :ok
  end

  private

  def match_params
    params.require(:match).permit(:participants, :open)
  end

  def prepare_match
    @match ||= current_round.matches.find_by(local_id: params[:number])
    head :not_found unless @match
  end

  def matchmake_params
    params.require(:matchmake).permit(within: [], between: [])
  end
end

class Test
  def initialize(**hash)
    hash.each do |key, value|
      self.class.define_method("#{key}") do |arg|
        "#{value} Arg: #{arg}"
      end
    end
  end
end

class Discovery
  class << self
    def hi
      'die'
    end
  end
end
