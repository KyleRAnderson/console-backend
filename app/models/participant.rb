class Participant < ApplicationRecord
  belongs_to :roster, dependent: :destroy

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator
end
