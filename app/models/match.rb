class Match < ApplicationRecord
  belongs_to :round

  has_one :hunt, through: :round
  has_one :roster, through: :hunt
  # validate: false because validating the license would cause it to validate
  # matches again, and it's a bit of an unnecessary mess
  has_and_belongs_to_many :licenses, before_add: :on_add_license, validate: false
  has_many :participants, through: :licenses
  has_many :permissions, through: :roster

  validate :validate_two_unique_licenses
  validate :validate_unchanged_properties, on: :update
  validate :validate_licenses_in_hunt
  validate :validate_round_not_closed, on: :create
  validate :validate_licenses_no_other_matches_in_round, on: :create

  before_create :assign_local_id

  scope :ongoing_group, -> { joins(:licenses).distinct.group('matches.id').where(licenses: { eliminated: false }).having('count(licenses) = 2') }
  scope :ongoing, -> { where(id: ongoing_group.select(:id)) }
  scope :closed_group, -> { joins(:licenses).distinct.group('matches.id').where(licenses: { eliminated: true }).having('count(licenses) >= 1') }
  scope :closed, -> { where(id: closed_group.select(:id)) }
  scope :exact_licenses, ->(licenses) do
          joins(:licenses)
            .where(licenses: { id: licenses.map { |license| license.instance_of?(String) ? license : license.id } })
            .distinct
            .group(:id)
            .having('count(licenses) >= 2')
        end

  include MatchEdit

  def open?
    !closed?
  end

  def closed?
    licenses.any?(&:eliminated)
  end

  def to_param
    # Use local ID instead of actual ID for URLs.
    local_id
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
    return unless round

    proper_licenses = licenses.all? { |license| license.hunt == round.hunt }
    errors.add(:match, 'must have licenses which belong to the round\'s hunt') unless proper_licenses
  end

  def validate_round_not_closed
    errors.add(:match, 'cannot be associated with a closed round.') if round&.closed?
  end

  # Needs to be called after validations, which means that round has been assigned.
  def assign_local_id
    self.local_id = round.hunt.increment_match_id
  end

  def on_add_license(_)
    throw :abort unless new_record? && licenses.size < 2
  end

  def validate_licenses_no_other_matches_in_round
    return unless round

    if round.matches.joins(:licenses).where(licenses: { id: licenses.map(&:id) }).present?
      errors.add(:match, 'cannot be associated with licenses that already have a match in the round')
    end
  end
end
