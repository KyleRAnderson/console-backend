module TemporaryFixes
  # FIXME this is temporary until the rspec-rails gem is updated to fix this issue: https://github.com/rspec/rspec-rails/issues/2439
  # See https://gitlab.com/hunt-console/console-backend/-/issues/1
  def fixture_file_upload(path, mime_type = nil)
    Rack::Test::UploadedFile.new(Pathname.new(file_fixture_path).join(path), mime_type, false)
  end
end
