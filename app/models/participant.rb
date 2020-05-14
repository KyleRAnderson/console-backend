class Participant < ApplicationRecord
  belongs_to :roster
  has_many :licenses, dependent: :destroy

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator
end
