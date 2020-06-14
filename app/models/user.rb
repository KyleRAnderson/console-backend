require 'uri'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  before_destroy :cleanup_rosters

  has_many :permissions, dependent: :destroy
  has_many :rosters, foreign_key: 'owner_id'
  has_many :shared_rosters, class_name: 'Roster', through: :permissions, source: :roster

  validates_format_of :password, with: /\A[A-Za-z0-9\.!@#$%\^&\*\(\)_\+\-=]*\z/,
                                 message: 'must be unicode characters.'

  private

  def cleanup_rosters
    grouped = rosters.group_by { |roster| roster.permissions.blank? }
    # Destroy rosters for whom this owner was the last person
    grouped[true]&.each(&:destroy!)
    # For the rest, promote another user to the owner position.
    grouped[false]&.each(&:promote_user!)
  end
end
