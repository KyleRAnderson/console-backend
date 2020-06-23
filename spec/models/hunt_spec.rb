require 'rails_helper'
require 'support/record_saving'

RSpec.describe Hunt, type: :model do
  subject(:hunt) { create(:hunt) }

  describe 'construction' do
    let(:roster) { create(:roster) }
    subject(:hunt) { Hunt.new(roster: roster, name: 'test') }

    it 'can be created with valid attributes' do
      expect(hunt.save).to be true
    end

    it 'cannot be saved without a name' do
      hunt.name = nil
      cannot_save_and_errors(hunt)
    end

    it 'cannot be saved without an associated roster' do
      hunt.roster = nil
      cannot_save_and_errors(hunt)
    end
  end

  describe 'match id update' do
    it 'increases the hunt\'s match id' do
      expect { hunt.increment_match_id }.to change(hunt, :current_match_id).by(1)
    end

    describe 'concurrency' do
      # Need to use before(:all) otherwise it's too late to turn off transactional tests.
      before(:all) do
        self.use_transactional_tests = false
        @test_hunt = create(:hunt)
      end
      after(:all) do
        # Destroy owner since then everything else will be destroyed too.
        @test_hunt.roster.owner.destroy!
        self.use_transactional_tests = true
      end

      it 'prevents simultaneous increments to the math id' do
        begin
          # Make sure the connection pool size is what we expect before proceeding.
          expect(ActiveRecord::Base.connection.pool.size).to eq(5)
          NUM_THREADS = 4
          waiting = true
          hunt_id = @test_hunt.id

          threads = NUM_THREADS.times.map do
            Thread.new do
              hunt = Hunt.find(hunt_id)
              true while waiting
              hunt.increment_match_id
            end
          end
          waiting = false
          threads.each(&:join)

          expect(@test_hunt.reload.current_match_id).to eq(NUM_THREADS)
        ensure
          ActiveRecord::Base.connection_pool.disconnect!
        end
      end
    end
  end

  describe 'current highest round' do
    it 'returns 0 when no rounds have been created' do
      expect(hunt.current_highest_round_number).to be_zero
    end

    it 'increases when new rounds are created' do
      expect { create(:round, hunt: hunt) }.to change(hunt, :current_highest_round_number).by(1)
    end
  end
end
