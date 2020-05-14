class Hunt < ApplicationRecord
  validates :name, presence: true

  belongs_to :roster
  has_many :licenses, dependent: :destroy
  has_many :participants, through: :licenses
end
