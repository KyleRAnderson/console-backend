class Round < ApplicationRecord
  belongs_to :hunt
  has_many :matches, dependent: :destroy

  before_validation :auto_assign_number, on: :create, if: Proc.new { number.nil? }

  validates :number, numericality: { only_integer: true, greater_than: 0 }
  validate :validate_no_other_round_with_same_number

  def validate_no_other_round_with_same_number
    if hunt&.rounds&.find_by(number: number)
      errors.add(:round, "Only one round with number #{number} may exist per hunt.")
    end
  end

  def auto_assign_number
    unless hunt.nil?
      # We use count here specifically, since count refers to the number in the database.
      self.number = hunt.rounds.count > 0 ? hunt.rounds.order(number: :desc).first.number + 1 : 1
    end
  end

  def increment_match_id
    self.update(current_match_id: current_match_id + 1)
  end

  # Determines if this round is "closed" (it is not the current round)
  def closed?
    hunt.rounds.order(number: :desc).first.number > number
  end
end
