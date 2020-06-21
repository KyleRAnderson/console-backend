require 'rails_helper'

RSpec.describe LicensePolicy, type: :policy do
  subject { LicensePolicy }

  include_examples 'console policy' do
    let(:record) { create(:license, hunt: create(:hunt, roster: roster)) }

    include_examples 'console scope', License do
      let(:expected_records) do
        records = []
        %i[owner administrator operator viewer].each do |level|
          roster = create(:permission, level: level, user: user).roster
          records += create_list(:license, 15, hunt: create(:hunt, roster: roster))
        end
        records
      end

      before(:each) do
        expected_records
        create_list(:hunt_with_licenses, 2)
      end
    end
  end
end
