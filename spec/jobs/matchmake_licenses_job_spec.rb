require 'rails_helper'

RSpec.describe MatchmakeLicensesJob, type: :job do
  subject { described_class }
  let(:hunt) { create(:hunt) }
  context 'with a hunt containing no matches' do
    let!(:licenses) { create_list(:license, 12, hunt: hunt) }

    shared_examples 'all licenses' do |extra_message|
      def round_matcher
        be_present
      end

      it "selects all licenses for matchmaking #{extra_message}" do
        matchmaker = double(subject)
        matches = double(MatchList)
        allow(Matchmake).to receive(:new).and_return(matchmaker)
        expect(matchmaker).to receive(:matchmake).and_return(matches)
        expect(matches).to receive(:save_all)

        subject.perform_later(hunt, {})
        expect(Matchmake).to have_received(:new).with(match_array(licenses), hash_including(round_id: round_matcher, within: be_blank, between: be_blank))
      end
    end

    context 'and no rounds' do
      around(:example) do |example|
        expect { example.run }.to(change(Round, :count).by(1))
      end

      include_examples 'all licenses', 'with the newly created round' do
        def round_matcher
          hunt.current_round.id
        end
      end
    end

    (1..5).each do |num_rounds|
      context "and #{num_rounds} #{'round'.pluralize(num_rounds)}" do
        let!(:latest_round) do
          rounds = create_list(:round, num_rounds, hunt: hunt)
          rounds.last
        end
        include_examples 'all licenses', 'with the current round' do
          def round_matcher
            latest_round.id
          end
        end
      end
    end
  end

  context 'with a hunt containing matches' do
    describe 'matchmaking through round 1 to 6' do
      start_num_licenses = 70
      transition_operations = [
        # Start with 70 licenses
        # Generates matches with all 70 licenses
        # Round 0 => 1:
        {
          # Number of licenses which should not have a match generated for them in the next round
          no_match: 1, # Since we have 70 licenses, this actually ends up keeping 2 out. ==> + 2
          # 68 matchmakable licenses, 34 matches
          # Number of matches for which to pass through both participants
          pass_through: 2, # + 4 licenses
          # Number of matches for which to eliminate both participants
          total_eliminate: 3, # - 6 licenses
        # 29 other matches, so - 29 licenses, + 29
        },
        # 35 licenses in play
        # Round 1 => 2
        {
          no_match: 1, # + 1 licenses
          # 34 matchmakable licenses, 17 matches
          pass_through: 1, # + 2 licenses
          total_eliminate: 2, # - 4 licenses
        # 14 other matches, so - 14 licenses, + 14
        },
        # 17 licenses in play
        # Round 2 => 3
        {
          no_match: 0, # Ends up keeping 1 for no match. + 1 licenses kept
          # 16 matchmakable, 8 matches
          pass_through: 1, # + 2 licenses
          total_eliminate: 0,
        # 7 other matches, so - 7 licenses, + 7
        },
        # 10 licenses in play
        {
          no_match: 0,
          # 10 matchmakable licenses, 5 matches
          pass_through: 2, # + 4 licenses
          total_eliminate: 2, # - 4 licenses
        # 1 other match, - 1 license, + 1 license
        },
        # 5 licenses in play
        {
          no_match: 0, # Ends up keeping 1 license out, + 1 kept
          # 4 matchmakable licenses, 2 matches
          pass_through: 0,
          total_eliminate: 0,
        # 2 matches, so - 2 licenses, + 2
        },
      # 3 licenses in play
      ]

      let(:licenses) do
        first_operation = transition_operations.first
        create_list(:license, start_num_licenses, eliminated: false, hunt: hunt)
      end

      def generate_matches(remaining_licenses, num_no_match)
        # If we have an odd number of matches, then we will actually need to matchmake with one less in there.
        num_no_match += 1 if (remaining_licenses.size - num_no_match).odd?
        passed_licenses = remaining_licenses.shift(num_no_match)
        matches = remaining_licenses.each_slice(2).map { |pair| create(:match, round: hunt.current_round, licenses: pair) }
        [passed_licenses, matches]
      end

      def perform_eliminations(matches, num_pass_throughs: 0, num_eliminates: 0)
        pass_through_licenses = matches.shift(num_pass_throughs).reduce([]) { |total, match| total + match.licenses }
        eliminate_license_ids = matches.shift(num_eliminates).reduce([]) { |total, match| total + match.licenses.pluck(:id) }
        half_eliminate_license_ids, remaining_licenses = matches.map { |match| [match.licenses.first.id, match.licenses.last] }.transpose
        eliminate_license_ids += half_eliminate_license_ids
        License.where(id: eliminate_license_ids).update_all(eliminated: true)
        remaining_licenses + pass_through_licenses
      end

      def perform_transition(remaining_licenses, transition_descriptor)
        num_match_eliminates = transition_descriptor[:match_eliminates]
        num_pass_throughs = transition_descriptor[:pass_through]
        num_eliminates = transition_descriptor[:total_eliminate]
        num_no_match = transition_descriptor[:no_match]

        remaining_licenses, new_matches = generate_matches(remaining_licenses, num_no_match)
        remaining_licenses + perform_eliminations(new_matches, num_pass_throughs: num_pass_throughs, num_eliminates: num_eliminates)
      end

      it 'invokes the matchmake engine with proper arguments each time' do
        remaining_licenses = licenses
        round = create(:round, hunt: hunt)

        matchmake_double = double(Matchmake)
        matchlist_double = double(MatchList)

        [*transition_operations, nil].each do |current_transition|
          expect(Matchmake).to receive(:new)
                                 .with(match_array(remaining_licenses), hash_including(round_id: round.id))
                                 .and_return(matchmake_double)
          expect(matchmake_double).to receive(:matchmake).and_return(matchlist_double)
          expect(matchlist_double).to receive(:save_all)

          subject.perform_later(hunt, {})

          if current_transition.present?
            remaining_licenses = perform_transition(remaining_licenses, current_transition)
            round = create(:round, hunt: hunt)
          end
        end
      end
    end
  end
end
