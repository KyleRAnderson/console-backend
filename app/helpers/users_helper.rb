module UsersHelper
  def custom_confirmation_path(resource, confirmation_token: nil)
    if resource.class == User
      return FrontendHelper.frontend_user_confirmation_url(confirmation_token: confirmation_token)
    end

    confirmation_url(resource, confirmation_token: confirmation_token)
  end

  def custom_edit_password_url(resource, reset_password_token: nil)
    if resource.class == User
      return FrontendHelper.frontend_user_password_reset_url(confirmation_token: reset_password_token)
    end

    edit_password_url(resource, reset_password_token: reset_password_token)
  end
end
