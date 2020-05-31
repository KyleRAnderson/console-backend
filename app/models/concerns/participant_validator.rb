class ParticipantValidator < ActiveModel::Validator
  def validate(participant)
    return unless participant.roster
    participant_extras = participant.extras.clone
    participant.roster.participant_properties.each do |key|
      if participant_extras.has_key?(key)
        unless participant_extras[key].class == String
          participant.errors.add(:extras, "property #{key} is supposed to have a string value.")
        end
        participant_extras.delete(key)
      else
        participant.errors.add(:extras,
                               "missing definition for property #{key}")
      end
    end
    if participant_extras && !participant_extras.empty?
      participant.errors.add(:extras,
                             "has unexpected properties: #{participant_extras.keys.join(',')}")
    end
  end
end
