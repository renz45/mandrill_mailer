if defined?(Rails)
  require 'rails'
  module MandrillMailer
    class Railtie < Rails::Railtie
      config.mandrill_mailer = ActiveSupport::OrderedOptions.new
    end
  end
end