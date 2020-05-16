require 'rails_helper'

RSpec.describe Api::V1::HuntsHelper, type: :helper do
  let(:user) { create(:user) }
  let(:roster) { user.rosters.first }
  let(:hunt) { roster.hunts.first }

  it 'correctly formats hunt for json response' do
    value = helper.json_hunt(hunt)
    expect(value).to have_key(:hunt)
    expect(value).to have_key(:num_licenses)
    expect(value[:num_licenses]).to eq(hunt.licenses.length)
  end
end
