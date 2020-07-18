# frozen_string_literal: true

class MatchEditArgumentError < ArgumentError
  attr_reader :errors

  def initialize(error_hash)
    @errors = error_hash
  end

  def message
    'Invalid arguments for match editing'
  end
end

module MatchConcern
  extend ActiveSupport::Concern

  EMPTY_PAIRINGS_ERROR_MESSAGE = 'Must not have empty pairings.'
  DUPLICATE_LICENSE_IDS_ERROR_MESSAGE = 'Must not have the same license twice in  license id pairings.'
  NO_ROUND_ERROR_MESSAGE = 'Must have round provided.'
  IMPROPER_PAIRINGS = 'Must have pairings of two licenses each.'

  class_methods do
    def validate_edit_arguments(round, license_id_pairings)
      flattened = license_id_pairings&.flatten
      errors = { messages: [] }
      unique = flattened&.uniq
      if unique&.size != flattened&.size
        # At this point, we may assume unique and flattened are defined (since nil != nil is false)
        errors[:messages] << DUPLICATE_LICENSE_IDS_ERROR_MESSAGE
        # Quadratic time with the select here but ¯\_(ツ)_/¯
        errors[:duplicates] = unique.select { |id| flattened.count(id) > 1 }
      end
      errors[:messages] << EMPTY_PAIRINGS_ERROR_MESSAGE if license_id_pairings.blank?
      errors[:messages] << NO_ROUND_ERROR_MESSAGE if round.blank?
      errors[:messages] << IMPROPER_PAIRINGS if license_id_pairings&.any? do |pairing|
        !pairing.instance_of?(Array) || pairing.size != 2
      end
      raise MatchEditArgumentError, errors if errors.values.any?(&:present?)

      flattened
    end

    # Creates a new match for the licenses in the given parings.
    # Expected format of license_id_pairings: [[license_a_id, license_b_id], [license_c_id, license_e_id], ...]
    # Returns a hash of format {new_matches: Match[], deleted_match_ids: string[], illegal_licenses: string[] of license IDs}
    # new_matches would be matches created as a result of running this.
    # deleted_match_ids are the IDs of matches that were deleted as a result of running this (or that would be deleted if commit is false)
    # illegal_license_ids are all the license IDs for which such an operation cannot be performed.
    # Set commit to true to save the changes. Otherwise, the changes will be made only in memory.
    def edit_matches(round, license_id_pairings, commit: true)
      flattened = validate_edit_arguments(round, license_id_pairings)

      # Make sure that the licenses are in the correct hunt
      illegal_licenses = License.where(id: flattened)
      illegal_licenses = illegal_licenses.where(hunt_id: nil)
        .or(illegal_licenses.where.not(hunt_id: round.hunt.id))
        .pluck(:id)
      legal_licenses = license_id_pairings.reject do |pairing|
        # Reject any pairing in which there is any license ID that is in the illegal_licenses array.
        # Also reject pairings that have a match in the current round between the two licenses already.
        (pairing & illegal_licenses).present? || Match
          .exact_licenses(pairing)
          .where(round: round)
          .first
          .present?
      end

      new_matches = legal_licenses.map { |licenses| round.matches.build(license_ids: licenses) }
      flattened_legal = legal_licenses.flatten
      matches_to_destroy = Match.joins(:licenses)
        .where(round: round, licenses: { id: flattened_legal }).distinct
      destroy_match_ids = matches_to_destroy.map(&:id)

      if commit
        Match.transaction do
          # Important to destroy first so that validations on the new matches pass.
          matches_to_destroy.destroy_all
          # Un-eliminate all licenses for which new matches are being created.
          License.where(id: flattened_legal).update_all(eliminated: false)
          new_matches.each(&:save)
        end
      end

      { new_matches: new_matches, illegal_license_ids: illegal_licenses, deleted_match_ids: destroy_match_ids }
    end
  end
end
