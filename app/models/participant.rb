class Participant < ApplicationRecord
  belongs_to :roster, dependent: :destroy
  has_many :participant_attributes
  accepts_nested_attributes_for :participant_attributes

  validates :first, presence: true
  validates :last, presence: true
  validates_associated :participant_attributes
  validates_with ParticipantValidator
end
