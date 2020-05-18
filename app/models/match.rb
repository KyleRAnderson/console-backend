class Match < ApplicationRecord
  belongs_to :round
  has_many :participants, through: :licenses
  has_and_belongs_to_many :licenses

  before_create :assign_local_id
  after_create :update_round_match_id

  validate :validate_two_unique_licenses
  validate :validate_unchanged_local_id, on: :update

  def validate_two_unique_licenses
    errors.add(:match, 'Match must have unique licenses.') unless licenses.uniq.length == licenses.length
    errors.add(:match, 'Match must have exactly two licenses.') unless licenses.length == 2
  end

  def validate_unchanged_local_id
    errors.add(:match, 'Cannot change local id after creation.') if local_id_changed?
  end

  # Needs to be called after validations, which means that round has been assigned.
  def assign_local_id
    self.local_id = round.current_match_id
  end

  def update_round_match_id
    round.incremenet_match_id
  end
end
