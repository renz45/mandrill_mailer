require 'mandrill_mailer/message_mailer'
module MandrillMailer
	class MandrillMessageJob < ActiveJob::Base
	  queue_as :default
	 
	  def perform(message, async, ip_pool, send_at)
	    mailer = MandrillMailer::MessageMailer.new
	    mailer.message = message
	    mailer.async = async
	    mailer.ip_pool = ip_pool 
	    mailer.send_at = send_at
	    
	  	mailer.deliver_now
	  end
	  def api_key
	    MandrillMailer.config.api_key
	  end

	  def mandrill_api
	     @mandrill_api ||= Mandrill::API.new(api_key)
	  end
	end
end