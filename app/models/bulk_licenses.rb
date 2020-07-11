class BulkLicenses
  attr_reader :succeeded, :failed

  def initialize(succeeded_licenses, failed_licenses)
    @succeeded = succeeded_licenses
    @failed = failed_licenses
  end

  def as_json(**options)
    { succeeded: succeeded, failed: failed }.as_json(**options)
  end

  def successful?
    failed.blank?
  end

  def status_code
    if successful?
      if succeeded.empty?
        :ok
      else
        :created
      end
    else
      :multi_status
    end
  end

  def new_licenses
    License.where(id: succeeded)
  end
end
