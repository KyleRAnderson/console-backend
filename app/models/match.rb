class Match < ApplicationRecord
  belongs_to :round
  has_and_belongs_to_many :licenses, before_add: :on_add_license
  has_many :participants, through: :licenses

  before_create :assign_local_id
  after_create :update_hunt_match_id
  before_destroy :allow_destroy
  after_destroy :disallow_destroy

  validate :validate_two_unique_licenses
  validate :validate_round_not_closed

  def as_json(**options)
    super(include: { licenses: { only: %i[id eliminated],
                               include: {
            participant: { only: %i[id first last extras] },
          } } }, **options)
  end

  protected

  def readonly?
    (!new_record? && !@being_destroyed) || super
  end

  private

  def validate_two_unique_licenses
    errors.add(:match, 'must have unique licenses.') unless licenses.uniq.length == licenses.length
    errors.add(:match, 'must have exactly two licenses.') unless licenses.length == 2
  end

  def validate_round_not_closed
    errors.add(:match, 'Cannot be associated with a closed round.') if round&.closed?
  end

  def allow_destroy
    @being_destroyed = true
  end

  def disallow_destroy
    @being_destroyed = false
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
