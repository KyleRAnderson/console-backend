class License < ApplicationRecord
  belongs_to :hunt
  belongs_to :participant
end
