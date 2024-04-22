require Rails.root.join('config/environments/deployed.rb')

Rails.application.configure do
  # We put log some important pieces of information at the :warn level,
  # so prod should log at the :warn level.
  config.log_level = :warn

  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'https://check-please.library.columbia.edu' }
end
