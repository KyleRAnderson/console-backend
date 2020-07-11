require 'rails_helper'
require 'support/console_policy'

RSpec.describe RoundPolicy, type: :policy do
  subject { RoundPolicy }

  include_examples 'console policy', exclude: [:update] do
    let(:record) { create(:round, hunt: create(:hunt, roster: roster)) }

    include_examples 'console scope', Round do
      let(:expected_records) do
        records = []
        %i[owner administrator operator viewer].each do |level|
          roster = create(:permission, level: level, user: user).roster
          records += create_list(:round, 4, hunt: create(:hunt, roster: roster))
        end
        records
      end

      before(:each) do
        expected_records
        create_list(:hunt_with_rounds, 2)
      end
    end
  end
end
