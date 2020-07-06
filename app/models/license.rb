class License < ApplicationRecord
  belongs_to :hunt
  belongs_to :participant

  has_one :roster, through: :hunt
  has_and_belongs_to_many :matches, before_add: :on_add_match
  has_many :permissions, through: :roster

  validates :participant, uniqueness: { scope: :hunt,
                                        message: 'one license may exist per participant per hunt.' }
  validate :validate_participant_in_roster
  validate :validate_only_changed_eliminated, on: :update
  # Match must be valid so we don't get more/less than two licenses per match
  validates_associated :matches

  scope :eliminated, -> { where(eliminated: true) }
  scope :not_eliminated, -> { where(eliminated: false) }
  scope :with_match_in_round, ->(round_numbers) { joins(matches: :round).where(matches: { rounds: { number: round_numbers } }).distinct }

  def as_json(**options)
    super(include: { participant: { only: %i[first last extras id] } },
          except: :participant_id, methods: :match_ids,
          **options)
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

  def match_ids
    matches.map(&:id)
  end
end
