require 'rails_helper'
require 'support/console_policy'

RSpec.describe HuntPolicy, type: :policy do
  subject { HuntPolicy }

  include_examples 'console policy' do
    let(:record) { create(:hunt, roster: roster) }

    include_examples 'console scope', Hunt do
      let(:expected_records) do
        records = []
        %i[owner administrator operator viewer].each do |level|
          roster = create(:permission, level: level, user: user).roster
          records += create_list(:hunt, 10, roster: roster)
        end
        records
      end

      before(:each) do
        expected_records
        create_list(:hunt, 2)
      end
    end
  end
end
