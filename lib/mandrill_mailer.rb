require 'action_view'
require 'mandrill_mailer/railtie'
require 'mandrill_mailer/mock'
require 'mandrill_mailer/transactional_mailer'
require 'mandrill_mailer/version'

module MandrillMailer
  def self.configure(&block)
    block.call(MandrillMailer::Railtie.config.mandrill_mailer)
  end

  def self.config
    MandrillMailer::Railtie.config.mandrill_mailer
  end
end