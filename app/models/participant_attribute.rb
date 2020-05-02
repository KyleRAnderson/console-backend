class ParticipantAttribute < ApplicationRecord
    belongs_to :participant, dependent: :destroy, required: true
    validates :key, presence: true
    validates :value, presence: true
end
