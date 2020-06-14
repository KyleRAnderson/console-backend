class Permission < ApplicationRecord
  # Order of the following two are important, need to destroy associated roster first if it's empty
  after_destroy :clean_up_roster,
                if: proc { |permission| permission.roster.permissions.empty? }
  after_destroy :reassign_owner,
                if: proc { |permission| permission.owner? && !permission.roster.destroyed? }

  belongs_to :roster
  belongs_to :user

  enum level: %i[owner administrator operator viewer]

  validates :level, uniqueness: { scope: :roster },
                    if: proc { |permission| permission.owner? }
  validate :validate_unchanged_user_roster, on: :update

  private

  def validate_unchanged_user_roster
    errors.add(:permission, 'cannot change associated user') if user_id_changed?
    errors.add(:permission, 'cannot change associated roster') if roster_id_changed?
  end

  def clean_up_roster
    roster.destroy!
  end

  def reassign_owner
    roster.permissions.order(level: :asc, created_at: :asc)
      .take(1).first.owner!
  end
end
