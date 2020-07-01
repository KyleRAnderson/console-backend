class LicensePolicy < ConsolePolicy
  def eliminate_all?
    update?
  end

  def eliminate_half?
    eliminate_all?
  end
end
