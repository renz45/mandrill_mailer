# Offline modifications for using MandrillMailer without actually sending
# emails through Mandrill's API. Particularly useful for acceptance tests.
#
# To use, just require this file (say, in your spec_helper.rb):
#
#   require 'mandrill_mailer/offline'
#
# And then if you wish you can look at the contents of
# MandrillMailer.deliveries to see whether an email was queued up by your test:
#
#   email = MandrillMailer::deliveries.detect { |mail|
#     mail.template_name == 'my-template' &&
#     mail.message['to'].any? { |to| to['email'] == 'my@email.com' }
#   }
#   expect(email).to_not be_nil
#
# Don't forget to clear out deliveries:
#
#   before :each { MandrillMailer.deliveries.clear }
#
require 'mandrill_mailer'

module MandrillMailer
  def self.deliveries
    @deliveries ||= []
  end

  class TemplateMailer
    def deliver_now
      MandrillMailer::Mock.new({
        :template_name    => template_name,
        :template_content => template_content,
        :message          => message,
        :async            => async,
        :ip_pool          => ip_pool,
        :send_at          => send_at
      }).tap do |mock|
         MandrillMailer.deliveries << mock
      end
    end
  end

  class MessageMailer
    def deliver_now
      MandrillMailer::Mock.new({
        :message          => message,
        :async            => async,
        :ip_pool          => ip_pool,
        :send_at          => send_at
      }).tap do |mock|
         MandrillMailer.deliveries << mock
      end
    end
  end
end
