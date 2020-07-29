class License < ApplicationRecord
  belongs_to :hunt
  belongs_to :participant

  has_one :roster, through: :hunt
  # Destroy all matches when the license is destroyed, since there's no point in keeping a record
  # of matches with only one license in them.
  has_and_belongs_to_many :matches, before_add: :on_add_match
  has_many :permissions, through: :roster

  validates :participant_id, uniqueness: { scope: :hunt,
                                           message: 'one license may exist per participant per hunt.' }
  validate :validate_participant_in_roster
  validate :validate_only_changed_eliminated, on: :update
  # Match must be valid so we don't get more/less than two licenses per match
  # Use case is a license gets updated to have one less match, but that would leave
  # the match in an invalid state with only one license.
  validates_associated :matches

  before_validation :obtain_participant_lock, on: :create
  before_destroy :destroy_associated_matches

  scope :eliminated, -> { where(eliminated: true) }
  scope :not_eliminated, -> { where(eliminated: false) }
  scope :with_match_in_round, ->(round_numbers) { joins(matches: :round).where(matches: { rounds: { number: round_numbers } }).distinct }

  include PgSearch::Model
  pg_search_scope :search_identifiable, associated_against: {
                                          participant: %i[first last extras],
                                        }, using: {
                                          tsearch: {
                                            prefix: true,
                                          },
                                        }

  singleton_class.class_eval do
    # Creates licenses for each of the participants given by ID in the given hunt.
    # If the participant_ids are nil, then every participant in the hunt's roster will have
    # a license created for them in the hunt.
    def create_for_participants(hunt, participant_ids = nil)
      # Use Participant here instead of hunt.roster.participants because we want to provide error messages
      # for unexpected participants
      participants = participant_ids.present? ? Participant.where(id: participant_ids) : hunt.roster.participants
      participant_ids = participants.no_license_in(hunt).pluck(:id)
      licenses = participant_ids.map { |participant_id| License.new(participant_id: participant_id, hunt: hunt) }
      imported = import licenses
      BulkLicenses.new(imported.ids, imported.failed_instances)
    end
  end

  private

  # Ensures that the participant to which this license is assigned is in the roster to which the hunt belongs
  def validate_participant_in_roster
    if hunt && participant&.roster != hunt.roster
      errors.add(:license, 'The participant for this license must be in the same roster to which the hunt belongs.')
    end
  end

  def validate_only_changed_eliminated
    if (changed.reject { |attribute| attribute == 'eliminated' }).size > 0
      errors.add(:license, 'Can only change \'eliminated\' property on licenses.')
    end
  end

  def on_add_match(match)
    throw :abort unless match.new_record? && match.licenses.size < 2
  end

  def match_numbers
    matches.map(&:local_id)
  end

  def destroy_associated_matches
    Match.joins(:licenses).destroy_by(licenses: { id: id })
  end

  def obtain_participant_lock
    return unless participant

    participant.lock!
  end
end
