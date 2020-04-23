require 'rails_helper'

RSpec.describe Participant, type: :model do
  let(:attribute_invalid) { ParticipantAttribute.new(key: 'invalid', value: 'test_invalid') }

  rosters = [Roster.create(name: 'test'), Roster.create(name: 'test', participant_properties: ['first']), Roster.create(name: 'test', participant_properties: ['first', 'second', 'third', 'fourth'])]
  rosters.each do |roster|

    attributes = roster.participant_properties.map { |property| ParticipantAttribute.new(key: property, value: "test-#{property}")}
    subject(:participant) { described_class.new(roster: roster, first: 'firstname', last: 'lastname', participant_attributes: attributes) }

    it 'is valid with default construction' do
      expect(participant).to be_valid
    end

    it 'is not valid without a firstname' do
      participant.first = ''
      expect(participant).not_to be_valid
    end
    
    it 'is not valid without a lastname' do
      participant.last = ''
      expect(participant).not_to be_valid
    end

    it 'is not valid without required participant attributes' do
      if !roster.participant_properties.empty?
        participant.participant_attributes.clear
        expect(participant).not_to be_valid
      end
    end

    it 'is not valid with too many participant attributes' do
      participant.participant_attributes << attribute_invalid
      expect(participant).not_to be_valid
    end
  end
end
