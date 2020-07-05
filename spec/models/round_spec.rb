require 'rails_helper'
require 'support/record_saving'

RSpec.describe Round, type: :model do
  subject(:round) { create(:round) }

  describe 'construction' do
    let(:hunt) { create(:full_hunt, num_rounds: 4) }
    subject(:round) { build(:round, hunt: hunt) }

    context 'with valid configuration, no specified number' do
      it 'can be saved' do
        expected_number = round.hunt.rounds.order(number: :desc).first.number + 1
        expect(round.save).to be true
        expect(round.number).to eq(expected_number)
      end
    end

    describe 'with same number as already existing round' do
      it 'cannot be saved and has validation errors' do
        round.number = hunt.rounds.first.number
        cannot_save_and_errors(round)
      end
    end

    describe 'after a new round has been added after the current one' do
      it 'is closed' do
        expect(round.save).to be true
        expect(round).not_to be_closed
        create(:round, hunt: hunt)
        expect(round).to be_closed
      end
    end
  end

  describe 'ongoing matches' do
    it 'returns true if it has matches that are ongoing' do
      create_list(:match, 5, state: :ongoing, round: round)
      expect(round).to have_ongoing_matches
    end

    it 'returns false if it has matches but they are all closed' do
      create_list(:match, 5, state: :closed, round: round)
      create_list(:match, 5, state: :both_eliminated, round: round)
      expect(round).not_to have_ongoing_matches
    end

    it 'returns false if it has no matches' do
      expect(round).not_to have_ongoing_matches
    end
  end

  describe 'open/closed' do
    let(:hunt) { round.hunt }
    subject(:round) { create(:round) }

    it 'reports open/not closed when it is the current round in the hunt' do
      expect(round).to be_open
      expect(round).not_to be_closed
    end

    it 'reports closed/not open if there are rounds after it' do
      hunt.rounds.create
      expect(round).not_to be_open
      expect(round).to be_closed
    end

    it 'reports open/not closed if it is unsaved' do
      new_round = build(:round, hunt: hunt)
      expect(new_round).to be_open
      expect(new_round).not_to be_closed
    end
  end
end
