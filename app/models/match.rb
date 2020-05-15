class Match < ApplicationRecord
  belongs_to :round
  has_many :participants, through: :licenses
  has_and_belongs_to_many :licenses

  validate :validate_two_unique_licenses

  def validate_two_unique_licenses
    errors.add(:match, 'Match must have unique licenses.') unless licenses.uniq.length == licenses.length
    errors.add(:match, 'Match must have exactly two licenses.') unless licenses.length == 2
  end
end
