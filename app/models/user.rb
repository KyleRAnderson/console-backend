require 'uri'

class User < ApplicationRecord
    validates :username, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
