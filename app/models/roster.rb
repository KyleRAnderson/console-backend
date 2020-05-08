class Roster < ApplicationRecord
  belongs_to :user
  has_many :participants, dependent: :destroy
  serialize :participant_properties, Array

  validate :validate_unique_properties

  def validate_unique_properties
    unless self.participant_properties.uniq.length == self.participant_properties.length
      errors.add :roster, 'has duplicate properties.'
    end
  end
end
