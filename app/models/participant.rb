class Participant < ApplicationRecord
  require 'csv'
  include PgSearch::Model

  belongs_to :roster

  has_many :licenses, dependent: :destroy, before_add: :ensure_license_participant_unset
  has_many :matches, through: :licenses
  has_many :permissions, through: :roster

  validates :first, presence: true
  validates :last, presence: true
  validates_with ParticipantValidator

  scope :no_license_in, ->(hunt) do
          hunt = hunt.id if hunt.instance_of? Hunt
          joins(sanitize_sql_array(['LEFT OUTER JOIN licenses ON licenses.participant_id = participants.id AND licenses.hunt_id = ?', hunt]))
            .where(licenses: { hunt: nil })
        end

  pg_search_scope :search_by_name, against: %i[first last], using: {
                                     tsearch: { prefix: true },
                                   }
  pg_search_scope :search_identifiable,
                  against: %i[first last extras],
                  using: {
                    tsearch: { prefix: true },
                  }

  singleton_class.class_eval do # Same as class << self
    def csv_import(file, roster)
      raise ArgumentError, 'Invalid Extension' unless file.path.match?(/.*\.csv/i)

      participants = []
      header_converter = ->(header) { header.to_s.downcase.strip }
      expected_headers = Set.new(%w[first last] + roster.participant_properties)
      CSV.foreach(file.path, headers: true, header_converters: header_converter) do |row|
        raise ArgumentError, 'Wrong Headers' unless Set.new(row.headers) == expected_headers

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
