require 'uri'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    has_many :rosters
end
