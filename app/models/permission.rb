class Permission < ApplicationRecord
  belongs_to :roster
  belongs_to :user

  enum level: %i[owner administrator operator viewer]

  validate :validate_unchanged_properties, on: :update
  validate :validate_unchanged_owner, on: :update

  before_save :demote_owner, if: proc { |permission| permission.owner? && (permission.new_record? || permission.level_changed?) }
  # Order of the following two are important, need to destroy associated roster first if it's empty
  after_destroy :clean_up_roster,
                if: proc { |permission| permission.roster&.permissions&.reload&.blank? }
  after_destroy :reassign_owner,
                if: proc { |permission| permission.owner? && permission.roster && !permission.roster.destroyed? }

  def is_at_least?(level)
    # True if this permission is the same as the given level or higher.
    level = level.to_s
    role_order = Permission.levels.keys.reverse
    index = role_order.index(level)
    return false unless index

    role_order[index..].each do |role|
      return true if send(role + '?')
    end
    false
  end

  private

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
    # If this permission is just being created, the roster might not exist yet,
    # or may not have an owner yet. This might be the owner.
    roster&.owner&.update(level: :administrator)
  end

  def clean_up_roster
    roster.destroy!
  end

  def reassign_owner
    roster.permissions.order(level: :asc, created_at: :asc)
      .first.owner!
  end
end
