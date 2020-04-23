class ParticipantValidator < ActiveModel::Validator
    def validate(participant)
        participant.roster.participant_properties.each do |key|
            unless participant.participant_attributes.length <= participant.roster.participant_properties.length
                participant.errors.add :participant_attributes, "Participant has too many properties." 
            end
            found = participant.participant_attributes.select { |attribute| attribute.key == key }
            if !found
                participant.errors.add :participant_attributes, "Participant is missing property for #{key}."
            elsif found.length != 1
                participant.errors.add :participant_attributes, "Participant has multiple definitions for #{key}"
            end
        end
    end
end