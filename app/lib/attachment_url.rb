module AttachmentUrl
  @@host = Rails.application.config.action_mailer.default_url_options[:host]
  @@port = Rails.application.config.action_mailer.default_url_options[:port]

  # Performs the same function as rails_blob_url, but loads the hostname and port information from the mailer config.
  # If attachment is blank, nil is returned.
  def attachment_url(attachment)
    attachment.blank? ? nil : Rails.application.routes.url_helpers.rails_blob_url(attachment, host: @@host, port: @@port)
  end
end
