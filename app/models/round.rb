class Round < ApplicationRecord
  belongs_to :hunt

  has_one :roster, through: :hunt
  has_many :matches, dependent: :destroy
  has_many :permissions, through: :roster

  validates :number, numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: { scope: :hunt, message: 'must be unique across the hunt' }
  validate :validate_current_round_over, on: :create

  before_validation :auto_assign_number, on: :create, if: proc { number.blank? }

  # Determines if this round is "closed" (it is not the current round)
  def closed?
    hunt.rounds.order(number: :desc).first.number > number
  end

  def ongoing?
    matches.ongoing.present?
  end

  private

  def auto_assign_number
    unless hunt.nil?
      # We use count here specifically, since count refers to the number in the database.
      self.number = hunt.current_highest_round_number + 1
    end
  end

  def validate_current_round_over
    errors.add(:round, 'cannot be created with a round still ongoing') if hunt&.current_round&.ongoing?
  end
end
