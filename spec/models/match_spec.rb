require 'rails_helper'
require 'support/record_saving'

RSpec.describe Match, type: :model do
  let(:hunt) { round.hunt }
  let(:round) { create(:round) }
  let(:other_round) { create(:round) }
  let(:latest_round) { create(:round, hunt: round.hunt) }
  let(:other_participant) { create(:participant, roster: round.hunt.roster) }
  let(:other_license) { create(:license, participant: other_participant, hunt: round.hunt) }
  subject(:match) { create(:match) }

  describe 'construction' do
    subject(:match) { build(:match, round: round) }

    describe 'with valid configuration' do
      it 'can be saved and assigns itself a local id' do
        prev_round_match_id = hunt.current_match_id
        expect(match.save).to be true
        expect(match.local_id).to eq(prev_round_match_id + 1)
        expect(hunt.current_match_id).to eq(prev_round_match_id + 1)
      end
    end

    it 'cannot be saved with less than two licenses' do
      match.licenses.delete(match.licenses.first)
      cannot_save_and_errors(match)
    end

    it 'cannot be saved with more than two licenses' do
      expect { match.licenses.push(other_license) }.not_to change(match.licenses, :length)
      # I use to_a here because something funny happens with include? on an active record association proxy.
      expect(match.licenses.to_a).not_to include(other_license)
    end

    context 'with licenses from different hunts' do
      it 'cannot be saved' do
        license1 = build(:license)
        match.licenses.delete(match.licenses.first)
        match.licenses << license1
        cannot_save_and_errors(match)
      end
    end
    describe 'with closed round' do
      it 'cannot be saved' do
        latest_round
        cannot_save_and_errors(match)
      end
    end
  end

  it 'cannot change round after save' do
    match.round = other_round
    cannot_save_and_errors(match)
  end

  it 'reports open and closed properly' do
    match = create(:match, round: round, licenses: create_list(:license, 2, hunt: hunt, eliminated: false))
    expect(match).to be_open
    expect(match).not_to be_closed
    match.licenses.first.eliminated = true
    expect(match).not_to be_open
    expect(match).to be_closed
    match.licenses.last.eliminated = true
    expect(match).not_to be_open
    expect(match).to be_closed
  end
end
