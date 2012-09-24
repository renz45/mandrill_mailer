# MandrilMailer class for sending transactional emails through mandril.
# Only template based emails are supported at this time.

# Example usage:

# class InvitationMailer < MandrillMailer
#   default from: 'support@codeschool.com'

#   def invite(invitation)
#     mandrill_mail template: 'Group Invite',
#                   subject: I18n.t('invitation_mailer.invite.subject'),
#                   to: {email: invitation.email, name: 'user level 1'},
#                   vars: {
#                     'OWNER_NAME' => invitation.owner_name,
#                     'INVITATION_URL' => new_invitation_url(email: invitation.email, secret: invitation.secret)
#                   },
#                   template_content: {}
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

#   :template_content - A Hash of values and content for Mandrill editable content blocks.
#     In MailChimp templates there are editable regions with 'mc:edit' attributes that look
#     a little like: '<div mc:edit="header">My email content</div>' You can insert content directly into
#     these fields by passing a Hash {'header' => 'my email content'}

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

module MandrillMailer
  class TransactionalMailer
    # include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper

    # Public: Defaults for the mailer. Currently the only option is from:
    #
    # options - The Hash options used to refine the selection (default: {}):
    #             :from - Default from email address
    #
    # Examples
    #
    #   default from: 'foo@bar.com'
    #
    # Returns options
    def self.default(args)
      @@defaults ||= {}
      @@defaults[:from] ||= 'example@email.com'
      @@defaults.merge!(args)
    end

    # Public: setup a way to test mailer methods
    #
    # mailer_method - Name of the mailer method the test setup is for
    # block - Block of code to execute to perform the test. The mailer
    #         and options are passed to the block. The options have to
    #         contain at least the :email to send the test to.
    #
    # Examples
    #
    # test_setup_for :invite do |mailer, options|
    #   invitation = OpenStruct.new({
    #     email: options[:email],
    #     owner_name: 'foobar',
    #     secret: rand(9000000..1000000).to_s
    #   })
    #   mailer.invite(invitation).deliver
    # end
    #
    # Returns the duplicated String.
    def self.test_setup_for(mailer_method, &block)
      @@mailer_methods ||= {}
      @@mailer_methods[mailer_method] = block
    end

    # Public: Executes a test email
    #
    # mailer_method - Method to execute
    # options - The Hash options used to refine the selection (default: {}):
    #             :email - The email to send the test to.
    #
    # Examples
    #
    # InvitationMailer.test(:invite, email: 'benny@envylabs.com')
    #
    # Returns the duplicated String.
    def self.test(mailer_method, options={})
      unless options[:email]
        raise Exception 'Please specify a :email option(email to send the test to)'
      end

      if @@mailer_methods[mailer_method]
        @@mailer_methods[mailer_method].call(self.new, options)
      else
        raise Exception "The mailer method: #{mailer_method} does not have test setup"
      end

    end

    # Public: this enables the api key to be set in an initializer
    #         ex. MandrillMailer.api_key = ENV[MANDRILL_API_KEY]
    #
    # key - Api key for the Mandrill api
    #
    #
    # Returns the key(String)
    def self.api_key=(key)
      @@api_key = key
    end

    def default_url_options=(options={})
      @@url_host = options[:host]
    end

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
      mandrill = Mailchimp::Mandrill.new(api_key)
      mandrill.messages_send_template(@data)
    end

    # Public: Build the hash needed to send to the mandrill api
    #
    # args - The Hash options used to refine the selection:
    #             :template - Template name in Mandrill
    #             :subject - Subject of the email
    #             :to - Email to send the mandrill email to
    #             :vars - Merge vars used in the email for dynamic data
    #             :bcc - bcc email for the mandrill email
    #             :tags - Tags for the email
    #             :google_analytics_domains - Google analytics domains
    #             :google_analytics_campaign - Google analytics campaign
    #
    # Examples
    #
    # mandrill_mail template: 'Group Invite',
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

      @data = {"key" => api_key,
        "template_name" => args[:template],
        "template_content" => mandrill_args(args[:template_content]),
        "message" => {
          "subject" => args[:subject],
          "from_email" => args[:from] || @@defaults[:from],
          "from_name" => args[:from_name] || @@defaults[:from],
          "to" => args[:to],
          "headers" => args[:headers],
          "track_opens" => true,
          "track_clicks" => true,
          "auto_text" => true,
          "url_strip_qs" => true,
          "bcc_address" => args[:bcc],
          "global_merge_vars" => mandrill_args(args[:vars]),
          # "merge_vars" =>[
          #   {
          #     "rcpt" => "email@email.com"
          #     "vars" => {"name" => "VARS", "content" => "vars content"}
          #   }
          # ]

          "tags" => args[:tags],
          "google_analytics_domains" => args[:google_analytics_domains],
          "google_analytics_campaign" => args[:google_analytics_campaign]
          # "metadata" =>["..."],
          # "attachments" =>[
          #   {"type" => "example type", "name" => "example name", "content" => "example content"}
          # ]
        }
      }

      # return self so we can chain deliver after the method call, like a normal mailer.
      return self
    end

    def data
      @data
    end

    protected

    # Public: Url helper for creating OpenStruct compatible urls
    #         This is used for making sure urls will still work with
    #         OpenStructs used in the email testing code
    #
    #         OpenStruct should have a .url property to work with this
    #
    # object - Object that would normally be passed into the route helper
    # route_helper - The route helper as a symbol needed for the url
    #
    # Examples
    #
    # 'VIDEO_URL' => open_struct_url(video, :code_tv_video_url)
    #
    # Returns the url as a string
    def test_friendly_url(object, route_helper)
      if object.kind_of? OpenStruct
        object.url
      else
        method(route_helper).call(object)
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
      super || instance_methods.include?(method)
    end

    # Proxy route helpers to rails if Rails exists
    def method_missing(method, *args)
      return super unless defined?(Rails) && Rails.application.routes.url_helpers.respond_to?(method)
      Rails.application.routes.url_helpers.method(method).call(*args, host: @@url_host)
    end

    def image_path(image)
      ActionController::Base.helpers.asset_path(image)
    end

    def image_url(image)
      "#{root_url}#{image_path(image).split('/').reject!(&:empty?).join('/')}"
    end

    # convert a normal hash into the format mandrill needs
    def mandrill_args(args)
      args.map do |k,v|
        {'name' => k, 'content' => v}
      end
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
      return {"email" => item, "name" => "Code School Customer"} unless item.kind_of? Hash
      item
    end

    def api_key
      @@api_key || ''
    end
  end
end