class Hunt < ApplicationRecord
  validates :name, presence: true

  belongs_to :roster
end
