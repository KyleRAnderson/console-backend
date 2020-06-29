class Participant < ApplicationRecord
  require 'csv'

  belongs_to :roster

  has_many :licenses, dependent: :destroy, before_add: :ensure_license_participant_unset
  has_many :matches, through: :licenses
  has_many :permissions, through: :roster

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator

  singleton_class.class_eval do # Same as class << self
    def csv_import(file, roster)
      raise ArgumentError, 'Invalid Extension' unless file.path.match?(/.*\.csv/i)

      participants = []
      header_converter = ->(header) { header.to_s.downcase.strip }
      CSV.foreach(file.path, headers: true, header_converters: header_converter) do |row|
        hash = row.to_h
        required = hash.slice('first', 'last')
        # We include an except for roster here to make sure that it doesn't get included.
        required['extras'] = hash.except('first', 'last', 'roster')
        participants << Participant.new(roster: roster, **required)
      end
      import participants, all_or_none: true
    end
  end

  private

  def ensure_license_participant_unset(license)
    throw :abort unless license.participant.nil?
  end
end
