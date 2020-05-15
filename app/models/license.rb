class License < ApplicationRecord
  belongs_to :hunt
  belongs_to :participant
  has_and_belongs_to_many :matches

  validate :validate_one_license_per_participant_per_hunt

  def validate_one_license_per_participant_per_hunt
    if hunt && participant&.licenses&.find_by(hunt: hunt)
      errors.add(:license, 'Only one license may exist per participant per hunt.')
    end
  end
end
