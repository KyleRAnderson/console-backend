class Hunt < ApplicationRecord
  include AttachmentUrl

  belongs_to :roster

  has_many :licenses, dependent: :destroy
  has_many :rounds, dependent: :destroy
  has_many :participants, through: :licenses
  has_many :matches, through: :rounds
  has_many :permissions, through: :roster
  has_one_attached :template_pdf
  has_one_attached :license_printout

  validates :name, presence: true

  def increment_match_id
    with_lock do
      self.current_match_id += 1
      save!
    end
    self.current_match_id
  end

  def current_round_number
    current_round&.number || 0
  end

  def current_round
    rounds.order(number: :desc).first
  end

  private

  def num_active_licenses
    licenses.where(eliminated: false).count
  end

  def attachment_urls
    { template_pdf: attachment_url(template_pdf),
      printout: attachment_url(license_printout) }
  end
end
