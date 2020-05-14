class Round < ApplicationRecord
  belongs_to :hunt

  validates :number, numericality: { only_integer: true, greater_than: 0 }
end
