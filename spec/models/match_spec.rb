require 'rails_helper'
require 'support/record_saving'

RSpec.describe Match, type: :model do
  let(:hunt) { round.hunt }
  let(:round) { create(:round) }
  let(:other_round) { create(:round) }
  let(:latest_round) { create(:round, hunt: round.hunt) }
  let(:other_participant) { create(:participant, roster: round.hunt.roster) }
  let(:other_license) { create(:license, participant: other_participant, hunt: round.hunt) }
  subject(:match) { create(:match) }

  describe 'construction' do
    let(:licenses) { create_list(:license, 2, hunt: hunt) }
    subject(:match) { build(:match, round: round, licenses: licenses) }

    describe 'with valid configuration' do
      it 'can be saved and assigns itself a local id' do
        prev_round_match_id = hunt.current_match_id
        expect(match.save).to be true
        expect(match.local_id).to eq(prev_round_match_id + 1)
        expect(hunt.current_match_id).to eq(prev_round_match_id + 1)
      end
    end

    it 'cannot be saved with less than two licenses' do
      match.licenses.delete(match.licenses.first)
      cannot_save_and_errors(match)
    end

    it 'cannot be saved with more than two licenses' do
      expect { match.licenses.push(other_license) }.not_to change(match.licenses, :length)
      # I use to_a here because something funny happens with include? on an active record association proxy.
      expect(match.licenses.to_a).not_to include(other_license)
    end

    context 'with licenses from different hunts' do
      it 'cannot be saved' do
        license1 = build(:license)
        match.licenses.delete(match.licenses.first)
        match.licenses << license1
        cannot_save_and_errors(match)
      end
    end

    context 'with closed round' do
      it 'cannot be saved' do
        latest_round
        cannot_save_and_errors(match)
      end
    end

    context 'with licenses associated with a match in the same round' do
      before(:each) do
        create(:match, round: round, licenses: licenses)
      end

      it 'cannot be saved' do
        cannot_save_and_errors(match)
      end
    end
  end

  it 'cannot change round after save' do
    match.round = other_round
    cannot_save_and_errors(match)
  end

  it 'reports open and closed properly' do
    match = create(:match, round: round, licenses: create_list(:license, 2, hunt: hunt, eliminated: false))
    expect(match).to be_open
    expect(match).not_to be_closed
    match.licenses.first.eliminated = true
    expect(match).not_to be_open
    expect(match).to be_closed
    match.licenses.last.eliminated = true
    expect(match).not_to be_open
    expect(match).to be_closed
  end

  describe 'exact licenses scope' do
    let(:hunt) { create(:hunt) }
    let(:license_pair) { create_list(:license, 2, hunt: hunt) }
    let(:matching_matches) { build_list(:match, 2, licenses: license_pair) }

    before(:each) do
      index = 0
      (matching_matches.size + 1).times do |i|
        round = create(:round, hunt: hunt)
        if i.even?
          matching_matches[index].round = round
          matching_matches[index].save!
          index += 1
        else
          # Make a match with one of the two licenses in the pair, which shouldn't match.
          create(:match, licenses: [license_pair.first, create(:license, hunt: hunt)], round: round)
        end
        # Create some extra un-related matches to ensure we don't get these ones.
        create_list(:match, 2, round: round)
      end
    end

    it 'gets only matches with exactly the specified licenses' do
      expect(Match.exact_licenses(license_pair)).to match_array(matching_matches)
      expect(Match.exact_licenses(license_pair.map(&:id))).to match_array(matching_matches)
    end
  end

  describe 'editing' do
    RSpec::Matchers.define_negated_matcher :not_change, :change
    RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error

    let(:hunt) { create(:hunt) }

    describe 'invalid uses' do
      shared_examples 'raises exception with info' do |expected_message|
        def error_expectations(edit_return); end

        it 'raises an exception containing information about the error' do
          error_expectations = ->(error) do
            expect(error).to be_a(MatchEditArgumentError)
            expect(error.errors).to have_key(:messages)
            expect(error.errors[:messages]).to include(expected_message)
            error_expectations(error)
          end
          edit_return = nil
          expect { edit_return = Match.edit_matches(round, pairings) }.to(change(&lambda { Match.count }).by(0).and(raise_error(&error_expectations)))
        end
      end

      context 'with no pairings provided' do
        let(:pairings) { nil }
        include_examples 'raises exception with info', Match::EMPTY_PAIRINGS_ERROR_MESSAGE
      end

      context 'with malformed pairings provided' do
        let(:pairings) { create_list(:license, 3).map(&:id) }
        include_examples 'raises exception with info', Match::IMPROPER_PAIRINGS
      end

      context 'with duplicate license IDs in pairings' do
        let(:licenses) { create_list(:license, 11, hunt: hunt) }
        let(:pairings) { [2.times.map { licenses.first }] + licenses[1..].each_slice(2).to_a }
        include_examples 'raises exception with info', Match::DUPLICATE_LICENSE_IDS_ERROR_MESSAGE do
          def error_expectations(error)
            expect(error.errors).to have_key(:duplicates)
            expect(error.errors[:duplicates]).to contain_exactly(licenses.first)
          end
        end
      end
    end

    describe 'valid cases' do
      let(:round) { create(:round, hunt: hunt) }
      let(:other_matched) { create_list(:license, 11, hunt: hunt) }
      # matched_for_pairings and unmatched_for_pairings should be of the same length.
      let(:matched_for_pairings) { create_list(:license, 7, hunt: hunt) }
      let(:unmatched_for_pairings) { create_list(:license, 7, hunt: hunt) }
      let!(:matches_to_delete) do
        common_size = [other_matched.size, matched_for_pairings.size].min
        matches = other_matched[...common_size].zip(matched_for_pairings[...common_size]).map do |pairing|
          create(:match, round: round, licenses: pairing)
        end
        # Now to make other matches which shouldn't get deleted
        other_matched[common_size..].each_slice(2) { |pairing| create(:match, round: round, licenses: pairing) }
        matches
      end

      shared_examples 'valid match editing' do
        def illegal_id_expectations(value)
          expect(value[:illegal_license_ids]).to be_empty
        end

        def new_match_expectations(value)
          expect(value[:new_matches].size).to eq(pairings.size)
          expect(value[:new_matches]).to all be_persisted
          expect(value[:new_matches].map { |match| match.licenses.pluck(:id) }).to match_array(pairings)
        end

        def expected_size_change
          pairings.size - matches_to_delete.size
        end

        it 'deletes matches for licenses with matches and creates new ones' do
          value = nil
          expect { value = Match.edit_matches(round, pairings) }.to(change(&-> { Match.count })
            .by(expected_size_change)
            .and(not_raise_error))
          expect(value).to have_key(:new_matches)
          expect(value).to have_key(:illegal_license_ids)
          expect(value).to have_key(:deleted_match_ids)
          expect(value[:deleted_match_ids]).to match_array(matches_to_delete.map(&:id))
          matches_to_delete.each { |match| expect(Match.exists?(match.id)).to be false }
          new_match_expectations(value)
          illegal_id_expectations(value)
        end
      end

      context 'with matched licenses' do
        let(:pairings) { matched_for_pairings.map(&:id).zip(unmatched_for_pairings.map(&:id)) }
        include_examples 'valid match editing'
      end

      context 'with some matched and unmatched licenses' do
        let(:unmatched_pairs) { create_list(:license, 6, hunt: hunt).map(&:id).each_slice(2).to_a }
        let(:pairings) { unmatched_pairs + matched_for_pairings.map(&:id).zip(unmatched_for_pairings.map(&:id)) }
        include_examples 'valid match editing'
      end

      context 'with licenses that don\'t belong to the correct hunt' do
        let(:outside_licenses) { create_list(:license, 3) }
        let(:inside_licenses) { create_list(:license, 3, hunt: hunt) }
        let(:pairings) { outside_licenses.map(&:id).zip(inside_licenses.map(&:id)) }
        let!(:matches_to_delete) { [] }
        include_examples 'valid match editing' do
          def illegal_id_expectations(value)
            expect(value[:illegal_license_ids]).to match_array(outside_licenses.map(&:id))
          end

          def expected_size_change
            0
          end

          def new_match_expectations(value)
            expect(value[:new_matches]).to be_empty
          end
        end
      end
    end
  end
end
