class Permission < ApplicationRecord
  belongs_to :roster
  belongs_to :user

  enum level: %i[owner administrator operator viewer]

  validates :user, uniqueness: { scope: :roster, message: 'only one permission may exist per user per roster.' }
  validate :validate_unchanged_properties, on: :update
  validate :validate_unchanged_owner, on: :update

  before_save :demote_owner, if: proc { owner? && roster&.owner_permission != self }
  # Order of the following two are important, need to destroy associated roster first if it's empty
  after_destroy :clean_up_roster,
                if: proc { |permission| permission.roster&.permissions&.reload&.blank? }
  after_destroy :reassign_owner,
                if: proc { |permission| permission.owner? && permission.roster && !permission.roster.destroyed? }

  def self.at_least?(level, desired_access)
    # level is current level, desired_access is level to check it against.
    # Determines if level is desired_access or higher.
    level = level.to_s
    desired_access = desired_access.to_s
    all_levels = self.levels.keys.reverse
    index = all_levels.index(desired_access)
    all_levels[index..].include?(level)
  end

  def self.at_most?(level, desired_access)
    # level is current level, desired_access is level to check against.
    # Determines if level is desired_access or lower.
    level = level.to_s
    desired_access = desired_access.to_s
    all_levels = self.levels.keys
    index = all_levels.index(desired_access)
    all_levels[index..].include?(level)
  end

  def at_least?(level)
    # True if this permission is the same as the given level or higher.
    Permission.at_least?(self.level, level)
  end

  def at_most?(level)
    # True if this permission is the same as the given level or lower
    Permission.at_most?(self.level, level)
  end

  def as_json(**options)
    super(except: %i[user_id roster_id], methods: :email, **options)
  end

  private

  def email
    user.email
  end

  def validate_unchanged_properties
    errors.add(:permission, 'cannot change associated user') if user_id_changed?
    errors.add(:permission, 'cannot change associated roster') if roster_id_changed?
  end

  def validate_unchanged_owner
    return unless level_changed? && level_was == 'owner'
    errors.add :permission, 'cannot demote and leave roster with no owner'
  end

  def demote_owner
    # Demotes the owner in this permission's roster to an administrator
    # Need to skip validations and callbacks.
    roster&.owner_permission&.update_attribute(:level, :administrator)
  end

  def clean_up_roster
    roster.destroy!
  end

  def reassign_owner
    roster.permissions.order(level: :asc, created_at: :asc)
      .first.owner!
  end
end
