require 'rails_helper'
require 'support/record_saving'

def disallow_association_with(match)
  expect { license.matches.push(match) }.not_to change(license.matches, :length)
  # Use to_a because without funny stuff happens.
  expect(license.matches.to_a).not_to include(match)
end

RSpec.describe License, type: :model do
  let(:user) { create(:user_with_rosters, num_rosters: 2) }
  let(:roster) { user.rosters.first }
  let(:participant) { create(:participant, roster: roster) }
  let(:hunt) { roster.hunts.first }
  let(:participant_wrong_hunt) { user.rosters.second.participants.first }
  let(:round) { create(:round, hunt: hunt) }
  let(:saved_match) { create(:match, round: round, licenses: [hunt.licenses.first, hunt.licenses.second]) }
  let(:unsaved_match) { build(:match, round: round, licenses: [hunt.licenses.first, hunt.licenses.second]) }

  subject(:license) do
    build(:license,
          participant: participant,
          hunt: hunt)
  end

  it 'can be created with valid arguments' do
    expect(license.save).to be true
  end

  context 'with participant in different roster from hunt' do
    it 'cannot be created' do
      license.participant = participant_wrong_hunt
      cannot_save_and_errors(license)
    end
  end

  it 'cannot be created without participant' do
    license.participant = nil
    cannot_save_and_errors(license)
  end

  it 'cannot be created without hunt' do
    license.hunt = nil
    cannot_save_and_errors(license)
  end

  context 'with a license already existing for the participant' do
    it 'cannot be saved, and has errors' do
      create(:license, participant: participant, hunt: hunt)
      cannot_save_and_errors(license)
    end
  end

  describe 'upon updating attributes other than eliminated' do
    it 'doesn\'t update' do
      license.save! # Bang because this should work.
      license.participant = participant_wrong_hunt
      cannot_save_and_errors(license)
    end
  end

  describe 'upon updating eliminated attribute only' do
    it 'updates successfully' do
      license.save!
      license.eliminated = true
      expect(license.save).to be true
    end
  end

  context 'with an unsaved match that already has two licenses' do
    it 'will not allow the association' do
      disallow_association_with(unsaved_match)
    end
  end

  context 'with a match that has been saved' do
    it 'will not allow the association' do
      disallow_association_with(saved_match)
    end
  end

  describe 'upon destruction' do
    subject(:license) { create(:license, hunt: hunt) }
    let!(:associated_matches) do
      # Reason for creating rounds here is we can't have the same license in a match in the same round.
      3.times.map do
        create(:match, licenses: [license, create(:license, hunt: hunt)], round: create(:round, hunt: hunt))
      end
    end

    it 'destroys associated matches' do
      license.destroy!
      associated_matches.each { |match| expect(Match.exists?(match.id)).to be false }
    end
  end

  describe 'bulk creation from participants' do
    let(:roster) { create(:roster_with_participants, num_participants: 23) }

    context 'with hunt that has a license for each participant' do
      let!(:hunt) { create(:hunt_with_licenses, roster: roster) }

      it 'does nothing' do
        expectations = ->(licenses) do
          expect(licenses).to be_successful
          expect(licenses.succeeded).to be_empty
          expect(licenses.failed).to be_empty
        end
        expect { expectations.call(License.create_for_participants(hunt)) }.not_to(change { License.count })
        expect { expectations.call(License.create_for_participants(hunt, roster.participants.pluck(:id))) }.not_to(change { License.count })
      end
    end

    context 'with hunt that has no licenses for any of the participants' do
      let!(:hunt) { create(:hunt, roster: roster) }

      it 'creates a license for each participant with default arguments' do
        response = nil
        expect { response = License.create_for_participants(hunt) }.to change { License.count }.by(roster.participants.size)
        expect(response).to be_successful
        expect(response.succeeded.size).to eq(roster.participants.size)
        expect(response.new_licenses.pluck(:participant_id)).to match_array(roster.participants.pluck(:id))
        expect(response.failed).to be_empty
        expect(hunt.licenses.size).to eq(roster.participants.size)
        expect(hunt.licenses.pluck(:participant_id)).to match_array(roster.participants.pluck(:id))
      end

      it 'creates a license only for certain participants when specified' do
        selected_participants = roster.participants.each_slice(5).first
        response = nil
        selected_participant_ids = selected_participants.map(&:id)
        expect { response = License.create_for_participants(hunt, selected_participant_ids) }.to change { License.count }.by(selected_participants.size)
        expect(response).to be_successful
        expect(response.succeeded.size).to eq(selected_participant_ids.size)
        expect(response.new_licenses.pluck(:participant_id)).to match_array(selected_participant_ids)
        expect(hunt.licenses.pluck(:participant_id)).to match_array(selected_participant_ids)
      end
    end

    context 'with a hunt with licenses for some of the participants' do
      let!(:hunt) { create(:hunt, roster: roster) }
      let(:already_in) { roster.participants.first(5) }
      let(:not_in) { roster.participants.reject { |participant| already_in.include?(participant) } }
      let(:not_in_ids) { not_in.map(&:id) }

      before(:each) do
        already_in.each { |participant| create(:license, participant: participant, hunt: hunt) }
      end

      shared_examples 'bulk license creation' do
        it 'creates licenses for participants missing them only' do
          response = nil
          expected_count = roster.participants.size - already_in.size
          expect { response = License.create_for_participants(hunt) }.to change { License.count }.by(expected_count)
          expect(response).to be_successful
          expect(response.failed).to be_empty
          expect(response.succeeded.size).to eq(expected_count)
          expect(response.new_licenses.pluck(:participant_id)).to match_array(not_in_ids)
          expect(hunt.licenses.pluck(:participant_id)).to include(*not_in_ids)
        end

        it 'does not create licenses for particiapnts with one already, even if specified by ID' do
          not_to_create = already_in.first(3)
          to_create = not_in.first(4)
          participant_ids = (not_to_create + to_create).map(&:id)
          response = nil
          expect { response = License.create_for_participants(hunt, participant_ids) }.to change { License.count }.by(to_create.size)
          expect(response).to be_successful
          expect(response.failed).to be_empty
          expect(response.succeeded.size).to eq(to_create.size)
          expect(response.new_licenses.pluck(:participant_id)).to match_array(to_create.map(&:id))
          expect(hunt.licenses.pluck(:participant_id)).to include(*to_create.map(&:id))
        end
      end

      context('with no other hunts') { include_examples 'bulk license creation' }
      context 'with other hunts which have a license for all participants' do
        before(:each) { create_list(:hunt_with_licenses, 2, roster: roster) }
        include_examples 'bulk license creation'
      end

      context 'when participants from other roster are specified' do
        let(:other_participants) { create_list(:participant, 11) }
        it 'does not create licenses and reports the error' do
          response = nil
          expect { response = License.create_for_participants(hunt, other_participants.map(&:id)) }.not_to(change { License.count })
          expect(response.failed.size).to eq(other_participants.size)
          expect(response.failed.map(&:participant_id)).to match_array(other_participants.map(&:id))
        end
      end
    end
  end
end
