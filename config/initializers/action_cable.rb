# Be sure to restart your server when you modify this file.

# ActionCable server configuration
Rails.application.config.action_cable.mount_path = '/cable'
Rails.application.config.action_cable.allowed_request_origins = [
  'http://localhost:3000', 'https://localhost:3000',
  /http:\/\/localhost:.*/,
  # Add production domains here
]

# Enable debugging output in development
if Rails.env.development?
  Rails.application.config.action_cable.disable_request_forgery_protection = true
end
