module Api::V1::HuntsHelper
  def json_hunt(hunt)
    # Using hunt.licenses.count on purpose to only get the saved ones.
    { hunt: hunt, num_licenses: hunt.licenses.count }
  end
end
