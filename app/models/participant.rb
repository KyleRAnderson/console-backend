class Participant < ApplicationRecord
  belongs_to :roster

  has_many :licenses, dependent: :destroy, before_add: :ensure_license_participant_unset
  has_many :matches, through: :licenses
  has_many :permissions, through: :roster

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator

  private

  def ensure_license_participant_unset(license)
    throw :abort unless license.participant.nil?
  end
end
