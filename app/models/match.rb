class Match < ApplicationRecord
  belongs_to :round
  has_and_belongs_to_many :licenses, before_add: :on_add_license
  has_many :participants, through: :licenses

  before_create :assign_local_id
  after_create :update_hunt_match_id

  validate :validate_two_unique_licenses
  validate :validate_round_not_closed
  validate :validate_unchanged_properties, on: :update

  private

  def validate_two_unique_licenses
    errors.add(:match, 'Match must have unique licenses.') unless licenses.uniq.length == licenses.length
    errors.add(:match, 'Match must have exactly two licenses.') unless licenses.length == 2
  end

  def validate_unchanged_properties
    errors.add(:match, 'Cannot change local id after creation.') if local_id_changed?
    errors.add(:match, 'Cannot change round after creation.') if round_id_changed?
  end

  def validate_round_not_closed
    errors.add(:match, 'Cannot be associated with a closed round.') if round.closed?
  end

  # Needs to be called after validations, which means that round has been assigned.
  def assign_local_id
    self.local_id = round.hunt.current_match_id + 1
  end

  def update_hunt_match_id
    round.hunt.increment_match_id
  end

  def on_add_license(_)
    throw :abort unless new_record? && licenses.length < 2
  end
end
