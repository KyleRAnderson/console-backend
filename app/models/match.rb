class Match < ApplicationRecord
  belongs_to :round

  has_one :roster, through: :round
  has_and_belongs_to_many :licenses, before_add: :on_add_license
  has_many :participants, through: :licenses
  has_many :permissions, through: :roster

  validate :validate_two_unique_licenses
  validate :validate_unchanged_properties
  validate :validate_licenses_in_hunt
  validate :validate_round_not_closed

  before_create :assign_local_id

  scope :open, -> { joins(:licenses).group('matches.id').where(licenses: { eliminated: false }).having('count(licenses) = 2') }
  scope :closed, -> { joins(:licenses).group('matches.id').where(licenses: { eliminated: true }).having('count(licenses) >= 1') }

  def as_json(**options)
    super(include: { licenses: { only: %i[id eliminated],
                               include: {
            participant: { only: %i[id first last extras] },
          } } }, **options)
  end

  def open?
    !closed?
  end

  def closed?
    licenses.any?(&:eliminated)
  end

  private

  def validate_two_unique_licenses
    errors.add(:match, 'must have unique licenses.') unless licenses.uniq.size == licenses.size
    errors.add(:match, 'must have exactly two licenses.') unless licenses.size == 2
  end

  def validate_unchanged_properties
    errors.add(:match, 'cannot have attributes changed') if changed? && !new_record?
  end

  def validate_licenses_in_hunt
    proper_licenses = licenses.all? { |license| license.hunt == round.hunt }
    errors.add(:match, 'must have licenses which belong to the round\'s hunt') unless proper_licenses
  end

  def validate_round_not_closed
    errors.add(:match, 'Cannot be associated with a closed round.') if round&.closed?
  end

  # Needs to be called after validations, which means that round has been assigned.
  def assign_local_id
    self.local_id = round.hunt.increment_match_id
  end

  def on_add_license(_)
    throw :abort unless new_record? && licenses.size < 2
  end
end
