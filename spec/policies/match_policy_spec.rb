require 'rails_helper'
require 'support/console_policy'

RSpec.describe MatchPolicy, type: :policy do
  subject { MatchPolicy }

  include_examples 'console policy', exclude: %i[update destroy] do
    let(:owner) { roster.owner }
    let(:roster) { record.roster }
    let(:record) { create(:match) }

    # Extra go for matchmake
    include_examples 'modifiers', :matchmake

    include_examples 'console scope', Match do
      let(:expected_records) do
        records = []
        %i[owner administrator operator viewer].each do |level|
          roster = create(:permission, level: level, user: user).roster
          records += create_list(:match, 20, round: create(:round, hunt: create(:hunt, roster: roster)))
        end
        records
      end

      before(:each) do
        expected_records
        create_list(:roster_with_participants, 2)
      end
    end
  end
end
