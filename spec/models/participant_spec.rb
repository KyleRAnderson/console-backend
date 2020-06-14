require 'rails_helper'

RSpec.describe Participant, type: :model do
  let(:attribute_invalid) { { 'invalid': 'test_invalid' } }
  let(:attribute_wrong_type) { { 'first': {} } }
  let(:license) { create(:license) }

  shared_examples 'rosters' do |participant_properties|
    let(:roster) { create(:roster, participant_properties: participant_properties) }
    subject(:participant) do
      extras = roster.participant_properties.to_h { |property| [property, "test-#{property}"] }
      build(:participant, roster: roster, extras: extras)
    end

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

  [[], ['first'], ['first', 'second', 'third', 'fourth']].each do |properties|
    include_examples 'rosters', properties
  end
end
