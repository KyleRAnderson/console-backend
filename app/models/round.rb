class Round < ApplicationRecord
  belongs_to :hunt

  has_one :roster, through: :hunt
  has_many :matches, dependent: :destroy
  has_many :permissions, through: :roster

  validates :number, numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: { scope: :hunt, message: 'must be unique across the hunt' }

  before_validation :auto_assign_number, on: :create, if: proc { number.blank? }

  # True if this round is "closed" (it is not the current round)
  def closed?
    !open?
  end

  # True if this round is still open (the most recent round), false otherwise
  def open?
    new_record? || hunt.current_round == self
  end

  # True if this round has ongoing matches
  def has_ongoing_matches?
    matches.ongoing.present?
  end

  private

  def auto_assign_number
    unless hunt.blank?
      # We use count here specifically, since count refers to the number in the database.
      self.number = hunt.current_highest_round_number + 1
    end
  end
end
