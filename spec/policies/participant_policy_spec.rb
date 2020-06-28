require 'rails_helper'
require 'support/console_policy'

RSpec.describe ParticipantPolicy, type: :policy do
  subject { ParticipantPolicy }

  include_examples 'console policy' do
    let(:record) { create(:participant, roster: roster) }

    describe :upload do
      it 'denies access to viewers' do
        expect(subject.new(users[:viewer], roster)).to forbid_action(described_class)
      end

      it 'permits access to owners, administrators and operators' do
        users.slice(:owner, :administrator, :operator).values.each do |user|
          expect(subject.new(user, roster)).to permit_action(described_class)
        end
      end
    end

    include_examples 'console scope', Participant do
      let(:expected_records) do
        records = []
        %i[owner administrator operator viewer].each do |level|
          roster = create(:permission, level: level, user: user).roster
          records += create_list(:participant, 15, roster: roster)
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
