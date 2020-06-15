def cannot_save_and_errors(resource)
  expect(resource.save).to be false
  expect(resource.errors).not_to be_empty
end

def cannot_save_readonly(resource)
  expect { resource.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
end
