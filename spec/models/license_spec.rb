require 'rails_helper'

def cannot_save_and_errors(resource)
  expect(resource.save).to be false
  expect(resource.errors).not_to be_empty
end

RSpec.describe License, type: :model do
  let(:user) { create(:user, num_rosters: 2) }
  let(:roster) { user.rosters.first }
  let(:participant) { roster.participants.first }
  let(:hunt) { roster.hunts.first }
  let(:participant_wrong_hunt) { user.rosters.second.participants.first }

  subject(:license) do
    build(:license,
          participant: roster.participants.first,
          hunt: hunt)
  end

  it 'can be created with valid arguments' do
    expect(license.save).to be true
  end

  describe 'with participant in different roster from hunt' do
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

  describe 'with a license already existing for the participant' do
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
end
