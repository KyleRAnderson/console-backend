class Permission < ApplicationRecord
  belongs_to :roster
  belongs_to :user

  enum level: %i[administrator operator viewer]

  validate :validate_unchanged_user_roster, on: :update

  private

  def validate_unchanged_user_roster
    errors.add(:permission, 'cannot change associated user') if user_id_changed?
    errors.add(:permission, 'cannot change associated roster') if roster_id_changed?
  end
end
