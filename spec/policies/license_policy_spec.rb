require 'rails_helper'
require 'support/console_policy'

RSpec.describe LicensePolicy, type: :policy do
  subject { LicensePolicy }

  include_examples 'console policy' do
    let(:record) { create(:license, hunt: create(:hunt, roster: roster)) }

    %i[eliminate_all eliminate_half].each do |action|
      describe action do
        it 'denies viewers' do
          expect(subject.new(users[:viewer], record.hunt)).to forbid_action(described_class)
        end

        it 'permits owners, administrators and operators' do
          users.slice(:owner, :administrator, :operator).values.each do |user|
            expect(subject.new(user, record.hunt)).to permit_action(described_class)
          end
        end
      end
    end

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
