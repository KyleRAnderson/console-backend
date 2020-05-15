class Participant < ApplicationRecord
  belongs_to :roster
  has_many :licenses, dependent: :destroy
  has_many :matches, through: :licenses

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator
end
