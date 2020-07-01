require 'rails_helper'

RSpec.describe EliminateRemainingLicensesJob, type: :job do
  let(:hunt) { create(:hunt) }
  context 'when the hunt has no licenses' do
    it 'does nothing' do
      expect { EliminateRemainingLicensesJob.perform_now(hunt) }.not_to(change { License.eliminated.count })
    end
  end

  context 'when the hunt\'s licenses are all eliminated' do
    before(:each) { create_list(:license, 10, eliminated: true, hunt: hunt) }

    it 'does nothing' do
      expect { EliminateRemainingLicensesJob.perform_now(hunt) }.not_to(change { License.eliminated.count })
    end
  end

  context 'with a hunt where all licenses are not eliminated' do
    before(:each) do
      create_list(:license, 10, eliminated: false, hunt: hunt)
      create(:round_with_matches, hunt: hunt)
    end

    it 'eliminates all non-eliminated licenses' do
      EliminateRemainingLicensesJob.perform_now(hunt)
      expect(hunt.licenses.not_eliminated).to be_empty
      expect(hunt.licenses.eliminated.size).to eq(hunt.licenses.size)
    end
  end

  context 'with a hunt where each match has one eliminated license' do
    let(:licenses_map) { [true, false].to_h { |value| [value, create_list(:license, 5, eliminated: value, hunt: hunt)] } }

    before(:each) do
      round = create(:round, hunt: hunt)
      licenses_map
        .values
        .transpose
        .each { |licenses| create(:match, round: round, licenses: licenses) }
    end

    it 'does nothing' do
      EliminateRemainingLicensesJob.perform_now(hunt)
      expect(hunt.licenses.eliminated).to match_array(licenses_map[true])
      expect(hunt.licenses.not_eliminated).to match_array(licenses_map[false])
    end
  end

  context 'with a hunt with a mix of eliminated and not eliminated licenses' do
    # Need even number of licenses in to_be_eliminated
    let(:to_be_eliminated) { create_list(:license, 8, eliminated: false, hunt: hunt) }
    let(:already_eliminated) { create_list(:license, 7, eliminated: true, hunt: hunt) }
    let(:not_eliminated) { create_list(:license, 7, eliminated: false, hunt: hunt) }

    before(:each) do
      round = create(:round, hunt: hunt)
      match_creator = ->(licenses) { create(:match, round: round, licenses: licenses) }
      to_be_eliminated.each_slice(2, &match_creator)
      already_eliminated.zip(not_eliminated).each(&match_creator)
    end

    it 'eliminates only licenses in open matches' do
      EliminateRemainingLicensesJob.perform_now(hunt)
      expect(hunt.licenses.eliminated).to match_array(to_be_eliminated + already_eliminated)
      expect(hunt.licenses.not_eliminated).to match_array(not_eliminated)
    end
  end
end
