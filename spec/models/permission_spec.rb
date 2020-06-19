require 'rails_helper'

RSpec.describe Permission, type: :model do
  subject(:permission) { create(:permission) }
  let(:roster) { permission.roster }

  describe 'construction' do
    subject(:permission) { build(:permission) }

    context 'with valid construction' do
      describe 'saving the associated roster' do
        it 'saves the roster and the permission successsfully' do
          expect { expect(roster.save).to be true }.to change { roster.permissions.count }.by(1)
          expect(permission).not_to be_new_record
          expect(roster.permissions.first).to be_owner
        end
      end

      describe 'saving the permission' do
        it 'saves the roster and the permission successfully' do
          expect { expect(permission.save).to be true }.to change { Permission.count }.by(1)
          expect(roster).not_to be_new_record
        end
      end
    end

    context 'with invalid construction of permission' do
      it 'cannot be saved and is invalid' do
        permission.roster = nil
        cannot_save_and_errors(permission)
      end
    end

    context 'with invalid construction of roster' do
      it 'cannot be saved and is invalid' do
        roster.permissions.clear
        cannot_save_and_errors(roster)
      end
    end
  end

  describe 'immutability' do
    let(:other_user) { create(:user) }
    let(:other_roster) { create(:roster) }

    it 'cannot have its roster changed after creation' do
      permission.roster = other_roster
      cannot_save_and_errors(permission)
    end

    it 'cannot have its user changed after creation' do
      permission.user = other_user
      cannot_save_and_errors(permission)
    end
  end

  describe 'behaviour' do
    context 'with an owner already in the roster' do
      it 'demotes the owner to administrator, and promotes the permission' do
        new_permission = create(:permission, roster: roster, level: :owner)
        expect(permission.reload).to be_administrator
        expect(new_permission).to be_owner
      end
    end

    context 'with only one permission in the roster, who is the owner' do
      it 'destroys the roster if it is the last remaining permission' do
        permission.destroy!
        expect(roster).to be_destroyed
      end
    end

    context 'with other permissions in the roster' do
      let(:owner) { create(:permission) }
      let(:roster) { owner.roster }
      let(:admins) { create_list(:administrator, 2, roster: roster) }
      let(:ops) { create_list(:operator, 3, roster: roster) }
      let(:viewers) { create_list(:viewer, 5, roster: roster) }

      it 'promotes the oldest and highest permission user if owner is destroyed' do
        # Some very manual setup
        viewers[0].update(created_at: 1.year.ago)
        ops[0].update(created_at: 1.year.ago + 2.minutes)
        admins[0].update(created_at: 11.months.ago)
        ops[1].update(created_at: 11.months.ago + 2.days)
        viewers[1].update(created_at: 11.months.ago + 1.week)
        viewers[2].update(created_at: 9.months.ago)
        viewers[3].update(created_at: 8.months.ago)
        ops[2].update(created_at: 6.months.ago - 3.weeks)
        viewers[4].update(created_at: 9.days.ago)
        admins[1].update(created_at: 1.hour.ago)

        promotion_order = admins + ops + viewers

        # Skip the very last promotee because this one should cause deletion.
        promotion_order[0..-2].each do |promotee|
          roster.owner.destroy!
          expect(promotee.reload).to be_owner
          expect(roster.owner).to eq(promotee)
        end
      end

      it 'doesn\'t promote if non-owner is destroyed' do
        deletion_list = admins[0..0] + viewers[0..3] + ops[0..1] + admins[1..1]
        deletion_list.each do |to_delete|
          to_delete.destroy!
          expect(owner.reload).to be_owner
        end
      end
    end
  end
end
