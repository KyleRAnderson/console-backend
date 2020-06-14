class Roster < ApplicationRecord
  before_validation :strip_properties

  # Use delete_all so that we don't call hooks on the roster permissions.
  has_many :permissions, dependent: :delete_all
  has_many :participants, dependent: :destroy
  has_many :hunts, dependent: :destroy
  has_many :users, through: :permissions

  accepts_nested_attributes_for :permissions
  accepts_nested_attributes_for :users

  serialize :participant_properties, Array

  validates :name, presence: true
  validate :validate_proper_properties
  validate :validate_unique_properties
  validate :validate_nonempty_properties
  validate :validate_owner_present
  validate :validate_unchanged_participant_properties, on: :update

  private

  def strip_properties
    participant_properties.each(&:strip!)
  end

  def validate_proper_properties
    participant_properties.each do |property|
      unless property.match?(/^\S(.*\S)?$/)
        errors.add :roster, 'Participant properties must not have leading or trailing whitespace.'
      end
    end
  end

  def validate_unique_properties
    unless self.participant_properties.uniq.length == self.participant_properties.length
      errors.add :roster, 'has duplicate properties.'
    end
  end

  def validate_nonempty_properties
    self.participant_properties.each do |property|
      if property.empty?
        errors.add :roster, 'Roster has empty string participant properties'
      end
    end
  end

  def validate_owner_present
    errors.add(:roster, 'must have an associated owner') if permissions.blank?
  end

  def validate_unchanged_participant_properties
    if participant_properties_changed? && participants.count.positive?
      errors.add :roster, 'Roster\'s participant properties cannot be changed after participants have been added.'
    end
  end
end
