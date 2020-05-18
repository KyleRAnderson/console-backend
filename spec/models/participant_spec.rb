require 'rails_helper'

RSpec.describe Participant, type: :model do
  let(:attribute_invalid) { { 'invalid': 'test_invalid' } }
  let(:attribute_wrong_type) { { 'first': {} } }
  let(:license) { create(:license) }

  rosters = [Roster.create(name: 'test'),
             Roster.create(name: 'test', participant_properties: ['first']),
             Roster.create(name: 'test', participant_properties: ['first', 'second', 'third', 'fourth'])]

  rosters.each do |roster|
    attributes = roster.participant_properties.to_h { |property| [property, "test-#{property}"] }
    subject(:participant) {
      roster.participants.build(first: 'firstname',
                                last: 'lastname', extras: attributes)
    }

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
        participant.extras.clear
        expect(participant).not_to be_valid
      end
    end

    it 'is not valid with too many participant attributes' do
      participant.extras.merge!(attribute_invalid)
      expect(participant).not_to be_valid
    end

    it 'is not valid if the expected attribute is not a string' do
      unless participant.extras.empty?
        participant.extras.merge!(attribute_wrong_type)
        expect(participant).not_to be_valid
      end
    end

    describe 'while adding a license' do
      describe 'with a license that belongs to a participant already' do
        it 'doesn\'t add the license' do
          num_before = participant.licenses.length
          participant.licenses << license
          expect(participant.licenses.length).to eq(num_before)
          expect(participant.licenses.to_a).not_to include(license)
        end
      end
    end
  end
end
