class Participant < ApplicationRecord
  belongs_to :roster

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator
end
