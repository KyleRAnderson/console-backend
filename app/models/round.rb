class Round < ApplicationRecord
  belongs_to :hunt
  has_many :matches, dependent: :destroy

  validates :number, numericality: { only_integer: true, greater_than: 0 }
  validate :validate_no_other_match_with_same_number

  def validate_no_other_match_with_same_number
    if hunt&.rounds&.find_by(number: number)
      errors.add(:round, "Only one round with number #{number} may exist per hunt.")
    end
  end
end
