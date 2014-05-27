# MandrilMailer class for sending transactional emails through mandril.
# Only template based emails are supported at this time.

# Example usage:

# class InvitationMailer < MandrillMailer::TemplateMailer
#   default from: 'support@codeschool.com'

#   def invite(invitation)
#     mandrill_mail template: 'Group Invite',
#                   subject: I18n.t('invitation_mailer.invite.subject'),
#                   to: invitation.invitees.map {|invitee| { email: invitee.email, name: invitee.name }},
#                   # to: { email: invitation.email, name: invitation.recipient_name }
#                   vars: {
#                     'OWNER_NAME' => invitation.owner_name,
#                     'PROJECT_NAME' => invitation.project_name
#                   },
#                   recipient_vars: invitation.invitees.map do |invitee| # invitation.invitees is an Array
#                                     { invitee.email =>
#                                       {
#                                         'INVITEE_NAME' => invitee.name,
#                                         'INVITATION_URL' => new_invitation_url(invitee.email, secret: invitee.secret_code)
#                                       }
#                                     }
#                                   end,
#                   template_content: {},
#                   attachments: [{file: File.read(File.expand_path('assets/some_image.png')), filename: 'My Image.png', mimetype: 'image/png'}],
#                   important: true,
#                   inline_css: true
#   end
# end

# #default:
#   :from - set the default from email address for the mailer

# .mandrill_mail
#   :template(required) - Template name from within Mandrill

#   :subject(required) - Subject of the email

#   :to(required) - Accepts an email String, or hash with :name and :email keys
#     ex. {email: 'someone@email.com', name: 'Bob Bertly'}

#   :vars - A Hash of merge tags made available to the email. Use them in the
#     email by wrapping them in '*||*' vars: {'OWNER_NAME' => 'Suzy'} is used
#     by doing: *|OWNER_NAME|* in the email template within Mandrill
#
#   :recipient_vars - Similar to :vars, this is a Hash of merge tags specific to a particular recipient.
#     Use this if you are sending batch transactions and hence need to send multiple emails at one go.
#     ex. [{'someone@email.com' => {'INVITEE_NAME' => 'Roger'}}, {'another@email.com' => {'INVITEE_NAME' => 'Tommy'}}]

#   :template_content - A Hash of values and content for Mandrill editable content blocks.
#     In MailChimp templates there are editable regions with 'mc:edit' attributes that look
#     a little like: '<div mc:edit="header">My email content</div>' You can insert content directly into
#     these fields by passing a Hash {'header' => 'my email content'}

#   :attachments - An array of file objects with the following keys:
#       file: This is the actual file, it will be converted to byte data in the mailer
#       filename: The name of the file
#       mimetype: This is the mimetype of the file. Ex. png = image/png, pdf = application/pdf, txt = text/plain etc

#   :images - An array of embedded images to add to the message:
#       file: This is the actual file, it will be converted to byte data in the mailer
#       filename: The Content ID of the image - use <img src="cid:THIS_VALUE"> to reference the image in your HTML content
#       mimetype: The MIME type of the image - must start with "image/"

# :headers - Extra headers to add to the message (currently only Reply-To and X-* headers are allowed) {"...": "..."}

# :bcc - Add an email to bcc to

# :tags - Array of Strings to tag the message with. Stats are
#   accumulated using tags, though we only store the first 100 we see,
#   so this should not be unique or change frequently. Tags should be
#   50 characters or less. Any tags starting with an underscore are
#   reserved for internal use and will cause errors.

# :google_analytics_domains - Array of Strings indicating for which any
#   matching URLs will automatically have Google Analytics parameters appended
#   to their query string automatically.

# :google_analytics_campaign - String indicating the value to set for
#   the utm_campaign tracking parameter. If this isn't provided the email's
#   from address will be used instead.

# :inline_css - whether or not to automatically inline all CSS styles provided in the
#   message HTML - only for HTML documents less than 256KB in size

# :important - whether or not this message is important, and should be delivered ahead of non-important messages
require 'base64'

module MandrillMailer
  class TemplateMailer
    # include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper


    class InvalidEmail < StandardError; end
    class InvalidMailerMethod < StandardError; end
    class InvalidInterceptorParams < StandardError; end

    # Public: Defaults for the mailer. Currently the only option is from:
    #
    # options - The Hash options used to refine the selection (default: {}):
    #   :from - Default from email address
    #
    # Examples
    #
    #   default from: 'foo@bar.com'
    #
    # Returns options
    def self.default(args)
      @defaults ||= {}
      @defaults[:from] ||= 'example@email.com'
      @defaults.merge!(args)
    end
    class << self
      attr_accessor :defaults
    end

    # Public: setup a way to test mailer methods
    #
    # mailer_method - Name of the mailer method the test setup is for
    # 
    # block - Block of code to execute to perform the test. The mailer
    # and options are passed to the block. The options have to
    # contain at least the :email to send the test to.
    #
    # Examples
    #
    #   test_setup_for :invite do |mailer, options|
    #     invitation = OpenStruct.new({
    #       email: options[:email],
    #       owner_name: 'foobar',
    #       secret: rand(9000000..1000000).to_s
    #     })
    #     mailer.invite(invitation).deliver
    #   end
    #
    # Returns the duplicated String.
    def self.test_setup_for(mailer_method, &block)
      @mailer_methods ||= {}
      @mailer_methods[mailer_method] = block
    end

    # Public: Executes a test email
    #
    # mailer_method - Method to execute
    # 
    # options - The Hash options used to refine the selection (default: {}):
    #   :email - The email to send the test to.
    #
    # Examples
    #
    #   InvitationMailer.test(:invite, email: 'benny@envylabs.com')
    #
    # Returns the duplicated String.
    def self.test(mailer_method, options={})
      unless options[:email]
        raise InvalidEmail.new 'Please specify a :email option(email to send the test to)'
      end

      if @mailer_methods[mailer_method]
        @mailer_methods[mailer_method].call(self.new, options)
      else
        raise InvalidMailerMethod.new "The mailer method: #{mailer_method} does not have test setup"
      end

    end

    # Public: The name of the template to use
    attr_accessor :template_name

    # Public: Template content
    attr_accessor :template_content

    # Public: Other information on the message to send
    attr_accessor :message

    # Public: Enable background sending mode
    attr_accessor :async

    # Public:  Name of the dedicated IP pool that should be used to send the message
    attr_accessor :ip_pool

    # Public: When message should be sent
    attr_accessor :send_at

    # Public: Triggers the stored Mandril params to be sent to the Mandrill api
    #
    # text - The String to be duplicated.
    # count - The Integer number of times to duplicate the text.
    #
    # Examples
    #
    #   multiplex('Tom', 4)
    #   # => 'TomTomTomTom'
    #
    # Returns the duplicated String.
    def deliver
      mandrill = Mandrill::API.new(api_key)
      mandrill.messages.send_template(template_name, template_content, message, async, ip_pool, send_at)
    end

    # Public: Build the hash needed to send to the mandrill api
    #
    # args - The Hash options used to refine the selection:
    #             :template - Template name in Mandrill
    #             :subject - Subject of the email
    #             :to - Email to send the mandrill email to
    #             :vars - Global merge vars used in the email for dynamic data
    #             :recipient_vars - Merge vars used in the email for recipient-specific dynamic data
    #             :bcc - bcc email for the mandrill email
    #             :tags - Tags for the email
    #             :google_analytics_domains - Google analytics domains
    #             :google_analytics_campaign - Google analytics campaign
    #             :inline_css - whether or not to automatically inline all CSS styles provided in the message HTML
    #             :important - whether or not this message is important
    #             :async - whether or not this message should be sent asynchronously
    #             :ip_pool - name of the dedicated IP pool that should be used to send the message
    #             :send_at - when this message should be sent
    #
    # Examples
    #
    #   mandrill_mail template: 'Group Invite',
    #               subject: I18n.t('invitation_mailer.invite.subject'),
    #               to: invitation.email,
    #               vars: {
    #                 'OWNER_NAME' => invitation.owner_name,
    #                 'INVITATION_URL' => new_invitation_url(email: invitation.email, secret: invitation.secret)
    #               }
    #
    # Returns the the mandrill mailer class (this is so you can chain #deliver like a normal mailer)
    def mandrill_mail(args)

      # Mandrill requires template content to be there
      args[:template_content] = {"blank" => ""} if args[:template_content].blank?

      # format the :to param to what Mandrill expects if a string or array is passed
      args[:to] = format_to_params(args[:to])

      # Set the template name
      self.template_name = args.delete(:template)

      # Set the template content
      self.template_content = mandrill_args(args.delete(:template_content))

      self.async = args.delete(:async)
      self.ip_pool = args.delete(:ip_pool)
      if args.has_key?(:send_at)
        self.send_at = args.delete(:send_at).getutc.strftime('%Y-%m-%d %H:%M:%S')
      end

      # Construct message hash
      self.message = {
        "subject" => args[:subject],
        "from_email" => args[:from] || self.class.defaults[:from],
        "from_name" => args[:from_name] || self.class.defaults[:from_name] || self.class.defaults[:from],
        "to" => args[:to],
        "headers" => args[:headers],
        "important" => args[:important],
        "track_opens" => args.fetch(:track_opens, true),
        "track_clicks" => args.fetch(:track_clicks, true),
        "auto_text" => true,
        "inline_css" => args[:inline_css],
        "url_strip_qs" => args.fetch(:url_strip_qs, true),
        "preserve_recipients" => args[:preserve_recipients],
        "bcc_address" => args[:bcc],
        "global_merge_vars" => mandrill_args(args[:vars]),
        "merge_vars" => mandrill_rcpt_args(args[:recipient_vars]),
        "tags" => args[:tags],
        "subaccount" => args[:subaccount],
        "google_analytics_domains" => args[:google_analytics_domains],
        "google_analytics_campaign" => args[:google_analytics_campaign],
        "metadata" => args[:metadata],
        "attachments" => mandrill_attachment_args(args[:attachments]),
        "images" => mandrill_images_args(args[:images])
      }

      unless MandrillMailer.config.interceptor_params.nil?
        unless MandrillMailer.config.interceptor_params.is_a?(Hash)
          raise InvalidInterceptorParams.new "The interceptor_params config must be a Hash"
        end
        self.message.merge!(MandrillMailer.config.interceptor_params.stringify_keys)
      end

      # return self so we can chain deliver after the method call, like a normal mailer.
      return self
    end

    # Public: Data hash (deprecated)
    def data
      {
        "key" => api_key,
        "template_name" => template_name,
        "template_content" => template_content,
        "message" => message,
        "async" => async,
        "ip_pool" => ip_pool,
        "send_at" => send_at
      }
    end

    def from
      self.message && self.message['from_email']
    end

    def to
      self.message && self.message['to']
    end

    def bcc
      self.message && self.message['bcc_address']
    end

    protected

    def mandrill_attachment_args(args)
      return unless args
      args.map do |attachment|
        attachment.symbolize_keys!
        type = attachment[:mimetype]
        name = attachment[:filename]
        file = attachment[:file]
        {"type" => type, "name" => name, "content" => Base64.encode64(file)}
      end
    end

    def mandrill_images_args(args)
      return unless args
      args.map do |attachment|
        attachment.symbolize_keys!
        type = attachment[:mimetype]
        name = attachment[:filename]
        file = attachment[:file]
        {"type" => type, "name" => name, "content" => Base64.encode64(file)}
      end
    end

    # Makes this class act as a singleton without it actually being a singleton
    # This keeps the syntax the same as the orginal mailers so we can swap quickly if something
    # goes wrong.
    def self.method_missing(method, *args)
      return super unless respond_to?(method)
      new.method(method).call(*args)
    end

    def self.respond_to?(method, include_private = false)
      super || instance_methods.include?(method.to_sym)
    end

    # Proxy route helpers to rails if Rails exists. Doing routes this way
    # makes it so this gem doesn't need to be a rails engine
    def method_missing(method, *args)
      return super unless defined?(Rails) && Rails.application.routes.url_helpers.respond_to?(method)
      # Check to see if one of the args is an open struct. If it is, we'll assume it's the
      # test stub and try to call a path or url attribute.
      if args.any? {|arg| arg.kind_of?(MandrillMailer::Mock)}
        # take the first OpenStruct found in args and look for .url or.path
        args.each do |arg|
          if arg.kind_of?(MandrillMailer::Mock)
            break arg.url || arg.path
          end
        end
      else
        options = args.extract_options!.merge({host: MandrillMailer.config.default_url_options[:host], protocol: MandrillMailer.config.default_url_options[:protocol]})
        args << options
        Rails.application.routes.url_helpers.method(method).call(*args)
      end
    end

    def image_path(image)
      if defined? Rails
        ActionController::Base.helpers.asset_path(image)
      else
        method_missing(:image_path, image)
      end
    end

    def image_url(image)
      "#{root_url}#{image_path(image).split('/').reject!(&:empty?).join('/')}"
    end

    # convert a normal hash into the format mandrill needs
    def mandrill_args(args)
      return [] unless args
      args.map do |k,v|
        {'name' => k, 'content' => v}
      end
    end

    def mandrill_rcpt_args(args)
      return [] unless args
      args.map do |item|
        rcpt = item.keys[0]
        {'rcpt' => rcpt, 'vars' => mandrill_args(item.fetch(rcpt))}
      end
    end

    # ensure only true or false is returned given arg
    def format_boolean(arg)
      arg ? true : false
    end

    # handle if to params is an array of either hashes or strings or the single string
    def format_to_params(to_params)
      if to_params.kind_of? Array
        to_params.map do |p|
          to_params_item(p)
        end
      else
        [to_params_item(to_params)]
      end
    end

    # single to params item
    def to_params_item(item)
      return {"email" => item, "name" => item} unless item.kind_of? Hash
      item
    end

    def api_key
      MandrillMailer.config.api_key
    end
  end
end
