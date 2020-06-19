class Hunt < ApplicationRecord
  belongs_to :roster
  has_many :licenses, dependent: :destroy
  has_many :rounds, dependent: :destroy
  has_many :participants, through: :licenses
  has_many :matches, through: :rounds

  validates :name, presence: true

  def as_json(**options)
    super(methods: :num_active_licenses, **options)
  end

  def increment_match_id
    self.update(current_match_id: current_match_id + 1)
  end

  def current_highest_round_number
    # Use count instead of length or size specificaly to get the saved ones.
    current_round&.number || 0
  end

  def current_round
    rounds.order(number: :desc).first
  end

  def next_match_id
    current_match_id + 1
  end

  private

  def num_active_licenses
    licenses.where(eliminated: false).count
  end
end
