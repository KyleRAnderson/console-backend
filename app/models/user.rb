require 'uri'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :rosters, dependent: :destroy

  validates_format_of :password, with: /\A[A-Za-z0-9\.!@#$%\^&\*\(\)_\+\-=]*\z/,
                                 message: 'must be unicode characters.'
end
