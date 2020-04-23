class Roster < ApplicationRecord
    belongs_to :user, dependent: :destroy
    has_many :participants
    serialize :participant_properties, Array

    validate :validate_unique_properties

    def validate_unique_properties
        unless self.participant_properties.uniq.length == self.participant_properties.length
            errors.add :participant_properties, 'Participant properties has duplicate property names'
        end
    end
end
