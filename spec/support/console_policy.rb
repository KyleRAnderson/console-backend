RSpec.shared_examples 'console policy' do |exclude = {}|
  let(:owner) { build(:user) }
  let(:roster) { create(:roster, user: owner) }
  let(:users) do
    users = %i[administrator operator viewer].to_h do |level|
      [level, create(:permission, level: level, roster: roster).user]
    end
    users.merge(owner: owner)
  end

  context 'with a user that has no permission in the roster' do
    let(:user_no_access) { create(:user) }

    it 'denies access to all operations' do
      %i[index show create update destroy].reject { |level| exclude.include?(level) }.each do |action|
        expect(subject.new(user_no_access, record)).to forbid_action(action)
      end
    end
  end

  describe :show, if: exclude.exclude?(:show) do
    it 'allows all users access to the record' do
      users.values.each do |user|
        expect(subject.new(user, record)).to permit_action(described_class)
      end
    end
  end

  shared_examples 'modifiers' do |action|
    describe action do
      it 'permits owners, administrators and operators' do
        users.slice(:owner, :administrator, :operator).values.each do |user|
          expect(subject.new(user, record)).to permit_action(described_class)
        end
      end

      it 'denies viewers' do
        expect(subject.new(users[:viewer], record)).to forbid_action(described_class)
      end
    end
  end

  %i[create update destroy].reject { |action| exclude.include?(action) }.each do |action|
    include_examples 'modifiers', action
  end
end

RSpec.shared_examples 'console scope' do |query_class|
  let(:user) { create(:user) }
  describe '::Scope' do
    it 'filters proper acess' do
      resolved_scope = subject::Scope.new(user, query_class).resolve
      expect(resolved_scope).to match_array(expected_records)
    end
  end
end
