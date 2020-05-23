class Hunt < ApplicationRecord
  validates :name, presence: true

  belongs_to :roster
  has_many :licenses, dependent: :destroy
  has_many :rounds, dependent: :destroy
  has_many :participants, through: :licenses
  has_many :matches, through: :rounds

  def increment_match_id
    self.update(current_match_id: current_match_id + 1)
  end

  def current_highest_round_number
    # Use count instead of length or size specificaly to get the saved ones.
    current_round&.number || 0
  end

  def current_round
    rounds.order(number: :desc).first
  end
end
