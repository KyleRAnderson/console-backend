class Round < ApplicationRecord
  belongs_to :hunt

  has_one :roster, through: :hunt
  has_many :matches, dependent: :destroy
  has_many :permissions, through: :roster

  validates :number, numericality: { only_integer: true, greater_than: 0 }
  validate :validate_no_other_round_with_same_number

  before_validation :auto_assign_number, on: :create, if: proc { number.blank? }

  # Determines if this round is "closed" (it is not the current round)
  def closed?
    hunt.rounds.order(number: :desc).first.number > number
  end

  private

  def validate_no_other_round_with_same_number
    if hunt&.rounds&.find_by(number: number)
      errors.add(:round, "Only one round with number #{number} may exist per hunt.")
    end
  end

  def auto_assign_number
    unless hunt.nil?
      # We use count here specifically, since count refers to the number in the database.
      self.number = hunt.current_highest_round_number + 1
    end
  end
end
