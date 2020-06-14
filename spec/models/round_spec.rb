require 'rails_helper'

RSpec.describe Round, type: :model do
  let(:hunt) { create(:hunt_with_licenses_rounds, num_rounds: 4) }
  subject(:round) { build(:round, hunt: hunt) }

  describe 'with valid configuration, no specified number' do
    it 'can be saved' do
      expected_number = round.hunt.rounds.order(number: :desc).take(1).first.number + 1
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
