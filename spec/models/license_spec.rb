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
end
