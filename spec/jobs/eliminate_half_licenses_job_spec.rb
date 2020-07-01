require 'rails_helper'

RSpec.describe EliminateHalfLicensesJob, type: :job do
  let(:hunt) { round.hunt }
  let(:round) { create(:round) }

  context 'with no matches in the round' do
    it 'does nothing' do
      expect { EliminateHalfLicensesJob.perform_now(round) }.not_to(change { License.eliminated.count })
    end
  end

  context 'with matches where all licenses are not eliminated' do
    let(:round) { create(:round_with_matches, num_matches: 35) }

    it 'eliminates half the licenses' do
      before_count = round.hunt.licenses.not_eliminated.count
      EliminateHalfLicensesJob.perform_now(round)
      # Should be even number of licensese for 35 matches (70 licenses)
      expect(round.hunt.licenses.not_eliminated.count).to eq(before_count / 2)
      expect(round.matches).to all be_closed
    end
  end

  context 'with matches where all licenses are eliminated' do
    let(:hunt) { create(:hunt) }
    let(:round) { create(:round_with_matches, hunt: hunt) }

    before(:each) do
      create_list(:license, 10, eliminated: true, hunt: hunt)
    end

    it 'does nothing' do
      expect { EliminateHalfLicensesJob.perform_now(round) }.not_to(change { hunt.licenses.eliminated.count })
    end
  end

  context 'with matches with mixed open and closed matches' do
    let!(:both_eliminated_matches) do
      create_list(:license, 10, hunt: hunt, eliminated: true).each_slice(2).map do |licenses|
        create(:match, licenses: licenses, round: round)
      end
    end
    let!(:one_eliminated_matches) do
      [true, false].map { |value| create_list(:license, 5, eliminated: value, hunt: hunt) }.transpose.map do |licenses|
        create(:match, licenses: licenses, round: round)
      end
    end
    let!(:open_matches) do
      create_list(:license, 10, hunt: hunt, eliminated: false).each_slice(2).map do |licenses|
        create(:match, licenses: licenses, round: round)
      end
    end

    it 'eliminates only participants in open matches' do
      EliminateHalfLicensesJob.perform_now(round)
      expect(round.matches).to all be_closed
      open_matches.each do |match|
        expect(match.licenses.where(eliminated: true).count).to eq(1)
        expect(match.licenses.where(eliminated: false).count).to eq(1)
      end
    end
  end

  context 'when each match has one eliminated license' do
    let(:license_map) { [true, false].to_h { |value| [value, create_list(:license, 20, eliminated: value, hunt: hunt)] } }

    before(:each) do
      license_map
        .values
        .transpose
        .each { |licenses| create(:match, licenses: licenses, round: round) }
    end

    it 'does nothing' do
      expect { EliminateHalfLicensesJob.perform_now(round) }.not_to(change { hunt.licenses.eliminated.count })
      expect(hunt.licenses.eliminated).to match_array(license_map[true])
      expect(hunt.licenses.not_eliminated).to match_array(license_map[false])
      expect(round.matches).to all be_closed
    end
  end
end
