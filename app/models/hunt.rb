class Hunt < ApplicationRecord
  validates :name, presence: true

  belongs_to :roster
  has_many :licenses
  has_many :rounds, dependent: :destroy
  has_many :participants, through: :licenses
  has_many :matches, through: :rounds
end
