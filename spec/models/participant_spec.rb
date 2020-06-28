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
          num_before = participant.licenses.size
          participant.licenses << license
          expect(participant.licenses.size).to eq(num_before)
          expect(participant.licenses.to_a).not_to include(license)
        end
      end
    end
  end

  [[], ['first'], ['first', 'second', 'third', 'fourth']].each do |properties|
    include_examples 'rosters', properties
  end

  describe 'participant import' do
    let(:roster) { create(:roster, participant_properties: ['test']) }
    let(:wrong_extension) { fixture_file_upload('files/wrong_extension.tar') }
    let(:malformed_csv) { fixture_file_upload('files/malformed_csv.csv') }
    let(:invalid_participants) { fixture_file_upload('files/invalid_participants.csv') }
    let(:valid_file) { fixture_file_upload('files/valid.csv') }

    context 'with invalid files' do
      it 'throws an ArgumentError upon wrong file extension' do
        expect { Participant.csv_import(wrong_extension, roster) }.to raise_error(ArgumentError)
      end

      it 'throws CSV::MalformedCSVError upon malformed CSV' do
        expect { Participant.csv_import(malformed_csv, roster).to raise_error(ArgumentError) }
      end
    end

    context 'with invalid participants' do
      it 'returns an object containing the import errors, and no participants are imported' do
        count_before = Participant.count
        import_result = Participant.csv_import(invalid_participants, roster)
        expect(Participant.count).to eq(count_before)
        expect(import_result).to be_present
        expect(import_result.failed_instances.size).to eq(2)
      end
    end

    context 'with a valid file' do
      it 'successfully imports all participants' do
        expect { Participant.csv_import(valid_file, roster) }.to change(Participant, :count).by(33)
      end
    end
  end
end
