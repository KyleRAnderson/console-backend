require 'uri'

class User < ApplicationRecord
  has_many :permissions, dependent: :destroy
  has_many :rosters, through: :permissions

  validates :password, format: { with: /\A[A-Za-z0-9\.!@#$%\^&\*\(\)_\+\-=]*\z/,
                                 message: 'must be unicode characters.' }

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
end
