require 'rails_helper'
require 'support/console_policy'

RSpec.describe Licenses::BulkPolicy, type: :policy do
  subject { Licenses::BulkPolicy }

  include_examples 'console policy', only: %i[create] do
    let(:record) { roster }
  end
end
