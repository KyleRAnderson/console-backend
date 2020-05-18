class License < ApplicationRecord
  belongs_to :hunt
  belongs_to :participant
  has_and_belongs_to_many :matches

  validate :validate_one_license_per_participant_per_hunt, on: :create
  validate :validate_participant_in_roster
  validate :validate_only_changed_eliminated, on: :update
  # Match must be valid so we don't get more/less than two licenses per match
  validates_associated :matches

  def validate_one_license_per_participant_per_hunt
    if hunt && participant&.licenses&.find_by(hunt: hunt)
      errors.add(:license, 'Only one license may exist per participant per hunt.')
    end
  end

  # Ensures that the participant to which this license is assigned is in the roster to which the hunt belongs
  def validate_participant_in_roster
    if hunt && participant&.roster != hunt.roster
      errors.add(:license, 'The participant for this license must be in the same roster to which the hunt belongs.')
    end
  end

  def validate_only_changed_eliminated
    if (changed.select { |attribute| attribute != 'eliminated' }).length > 0
      errors.add(:license, 'Can only change \'eliminated\' property on licenses.')
    end
  end

  def as_json(options = {})
    super.as_json(options).merge({ participant: participant.as_json(only: %i[first last extras id]) })
  end
end
