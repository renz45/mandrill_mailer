# Mandrill Mailer
[![Gem Version](http://img.shields.io/gem/v/mandrill_mailer.svg)](rubygems.org/gems/mandrill_mailer)
[![Code Climate](http://img.shields.io/codeclimate/github/renz45/mandrill_mailer.svg)](https://codeclimate.com/github/renz45/mandrill_mailer)
[![Dependencies](http://img.shields.io/gemnasium/renz45/mandrill_mailer.svg)](https://gemnasium.com/renz45/mandrill_mailer)

Inherit the MandrillMailer class in your existing Rails mailers to send transactional emails through Mandrill using their template-based emails.

## Installation
Add this line to your application's Gemfile:

```
gem 'mandrill_mailer'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install mandrill_mailer
```

## Usage
Add the following to your `mail.rb` in your Rails app's `config/initializers` directory:

```ruby
ActionMailer::Base.smtp_settings = {
    :address   => "smtp.mandrillapp.com",
    :port      => 587,
    :user_name => ENV['MANDRILL_USERNAME'],
    :password  => ENV['MANDRILL_API_KEY'],
    :domain    => 'heroku.com'
  }
ActionMailer::Base.delivery_method = :smtp

MandrillMailer.configure do |config|
  config.api_key = ENV['MANDRILL_API_KEY']
end
```

You don't need to add the ActionMailer stuff unless you're still using ActionMailer emails.

This uses the Mandrill SMTP servers. If you're using template-based emails
through the Mandrill API you only need the `MandrillMailer.configure` portion.

Do not forget to setup the environment (`ENV`) variables on your server instead
of hardcoding your Mandrill username and password in the `mail.rb` initializer.

You will also need to set `default_url_options` for the mailer, similar to ActionMailer
in your environment config files in `config/environments`:

```ruby
config.mandrill_mailer.default_url_options = { :host => 'localhost' }
```

## Creating a new mailer
Creating a new Mandrill mailer is similar to a typical Rails one:

```ruby
class InvitationMailer < MandrillMailer::TemplateMailer
  default from: 'support@example.com'

  def invite(invitation)
    # in this example `invitation.invitees` is an Array
    invitees = invitation.invitees.map { |invitee| { email: invitee.email, name: invitee.name } }

    mandrill_mail(
      template: 'group-invite',
      subject: I18n.t('invitation_mailer.invite.subject'),
      to: invitees,
        # to: invitation.email,
        # to: { email: invitation.email, name: 'Honored Guest' },
      vars: {
        'OWNER_NAME' => invitation.owner_name,
        'PROJECT_NAME' => invitation.project_name
      },
      important: true,
      inline_css: true,
      recipient_vars: invitation.invitees.map do |invitee|
        { invitee.email =>
          {
            'INVITEE_NAME' => invitee.name,
            'INVITATION_URL' => new_invitation_url(
              invitee.email,
              secret: invitee.secret_code
            )
          }
        }
      end
     )
  end
end
```

* `#default:`
  * `:from` - set the default from email address for the mailer
  * `:from_name` - set the default from name for the mailer. If not set, defaults to from email address. Setting :from_name in the .mandrill_mail overrides the default.

* `.mandrill_mail`
   * `:template`(required) - Template slug from within Mandrill (for backwards-compatibility, the template name may also be used but the immutable slug is preferred)

   * `:subject` - Subject of the email. If no subject supplied, it will fall back to the template default subject from within Mandrill

   * `:to`(required) - Accepts an email String, a Hash with :name and :email keys, or an Array of Hashes with :name and :email keys
      - examples:
        1. `'example@domain.com'`
        2. `{ email: 'someone@email.com', name: 'Bob Bertly' }`
        3. `[{ email: 'someone@email.com', name: 'Bob Bertly' }, { email: 'other@email.com', name: 'Claire Nayo' }]`

   * `:vars` - A Hash of merge tags made available to the email. Use them in the
     email by wrapping them in `*||*`. For example `{'OWNER_NAME' => 'Suzy'}` is used by doing: `*|OWNER_NAME|*` in the email template within Mandrill

   * `:recipient_vars` - Similar to `:vars`, this is a Hash of merge vars specific to a particular recipient.
     Use this if you are sending batch transactions and hence need to send multiple emails at one go.
     ex. `[{'someone@email.com' => {'INVITEE_NAME' => 'Roger'}}, {'another@email.com' => {'INVITEE_NAME' => 'Tommy'}}]`

   * `:template_content` - A Hash of values and content for Mandrill editable content blocks.
     In MailChimp templates there are editable regions with 'mc:edit' attributes that look
     like: `<div mc:edit="header">My email content</div>` You can insert content directly into
     these fields by passing a Hash `{'header' => 'my email content'}`

   * `:headers` - Extra headers to add to the message (currently only `Reply-To` and `X-*` headers are allowed) {"...": "..."}

   * `:bcc` - Add an email to bcc to

   * `:tags` - Array of Strings to tag the message with. Stats are
   accumulated using tags, though we only store the first 100 we see,
   so this should not be unique or change frequently. Tags should be
   50 characters or less. Any tags starting with an underscore are
   reserved for internal use and will cause errors.

   * `:google_analytics_domains` - Array of Strings indicating for which any
   matching URLs will automatically have Google Analytics parameters appended
   to their query string automatically.

   * `:google_analytics_campaign` - String indicating the value to set for
   the utm_campaign tracking parameter. If this isn't provided the email's
   from address will be used instead.

   * `:important` - whether or not this message is important, and should be delivered ahead of non-important messages.

   * `:inline_css` - whether or not to automatically inline all CSS styles provided in the message HTML - only for HTML documents less than 256KB in size.

   * `:attachments` - An array of file objects with the following keys:
     * `content`: The file contents, this will be encoded into a base64 string internally
     * `name`: The name of the file
     * `type`: This is the mimetype of the file. Ex. png = image/png, pdf = application/pdf, txt = text/plain etc etc

   * `:images` - An array of embedded images to add to the message:
     * `content`: The file contents, this will be encoded into a base64 string internally
     * `name`: The name of the file
     * `type`: This is the mimetype of the file. Ex. png = image/png, pdf = application/pdf, txt = text/plain etc etc etc

   * `:async` - Whether or not this message should be sent asynchronously

   * `:ip_pool` - The name of the dedicated ip pool that should be used to send the message

   * `:send_at` - When this message should be sent

## Sending a message without template
Sending a message without template is similar to sending a one with a template. The biggest
change is that you have to inherit from `MandrillMailer::MessageMailer` instead of the
MandrillMailer::TemplateMailer class:

```ruby
class InvitationMailer < MandrillMailer::MessageMailer
  default from: 'support@example.com'

  def invite(invitation)
    # in this example `invitation.invitees` is an Array
    invitees = invitation.invitees.map { |invitee| { email: invitee.email, name: invitee.name } }

    # no need to set up template and template_content attributes, set up the html and text directly
    mandrill_mail subject: I18n.t('invitation_mailer.invite.subject'),
                  to: invitees,
                  # to: invitation.email,
                  # to: { email: invitation.email, name: 'Honored Guest' },
                  text: "Example text content",
                  html: "<p>Example HTML content</p>",
                  view_content_link: "http://www.nba.com",
                  vars: {
                    'OWNER_NAME' => invitation.owner_name,
                    'PROJECT_NAME' => invitation.project_name
                  },
                  important: true,
                  inline_css: true,
                  attachments: [
                    {
                      content: File.read(File.expand_path('assets/offer.pdf')),
                      name: 'offer.pdf',
                      type: 'application/pdf'
                    }
                  ],
                  recipient_vars: invitation.invitees.map do |invitee| # invitation.invitees is an Array
                    { invitee.email =>
                      {
                        'INVITEE_NAME' => invitee.name,
                        'INVITATION_URL' => new_invitation_url(invitee.email, secret: invitee.secret_code)
                      }
                    }
                  end
  end
end
```

## Sending an email

You can send the email by using the familiar syntax:

`InvitationMailer.invite(invitation).deliver`

## Creating a test method
When switching over to Mandrill for transactional emails we found that it was hard to setup a mailer in the console to send test emails easily (those darn designers), but really, you don't want to have to setup test objects everytime you want to send a test email. You can set up a testing 'mock' once and then call the `.test` method to send the test email.

You can test the above email by typing: `InvitationMailer.test(:invite, email:<your email>)` into the Rails Console.

The test for this particular Mailer is setup like so:

```ruby
test_setup_for :invite do |mailer, options|
    invitation = MandrillMailer::Mock.new({
      email: options[:email],
      owner_name: 'foobar',
      secret: rand(9000000..1000000).to_s
    })
    mailer.invite(invitation).deliver
end
```

Use MandrillMailer::Mock to mock out objects.

If in order to represent a url within a mock, make sure there is a `url` or `path` attribute,
for example, if I had a course mock and I was using the `course_url` route helper within the mailer
I would create the mock like so:

```ruby
course = MandrillMailer::Mock.new({
  title: 'zombies',
  type: 'Ruby',
  url: 'http://funzone.com/zombies'
})
```

This would ensure that `course_url(course)` works as expected.

The mailer and options passed to the `.test` method are yielded to the block.

The `:email` option is the only required option, make sure to add at least this to your test object.

## Offline Testing
You can turn on offline testing by requiring this file (say, in your spec_helper.rb):

```ruby
require 'mandrill_mailer/offline'
```

And then if you wish you can look at the contents of `MandrillMailer.deliveries` to see whether an email was queued up by your test:

```ruby
email = MandrillMailer::deliveries.detect { |mail|
  mail.template_name == 'my-template' &&
  mail.message['to'].any? { |to| to[:email] == 'my@email.com' }
}
expect(email).to_not be_nil
```

Don't forget to clear out deliveries:

```ruby
before :each { MandrillMailer.deliveries.clear }
```

## Using Delayed Job
The typical Delayed Job mailer syntax won't work with this as of now. Either create a custom job or que the mailer as you would que a method. Take a look at the following examples:

```ruby
def send_hallpass_expired_mailer
  HallpassMailer.hallpass_expired(user).deliver
end
handle_asynchronously :send_hallpass_expired_mailer
```

or using a custom job

```ruby
def update_email_on_newsletter_subscription(user)
  Delayed::Job.enqueue( UpdateEmailJob.new(user_id: user.id) )
end
```
The job looks like (Don't send full objects into jobs, send ids and requery inside the job. This prevents Delayed Job from having to serialize and deserialize whole ActiveRecord Objects and this way, your data is current when the job runs):

```ruby
class UpdateEmailJob < Struct.new(:user_id)
  def perform
    user = User.find(user_id)
    HallpassMailer.hallpass_expired(user).deliver
  end
end
```

## Using Sidekiq
Create a custom worker:

```ruby
class UpdateEmailJob
  include Sidekiq::Worker
  def perform(user_id)
    user = User.find(user_id)
    HallpassMailer.hallpass_expired(user).deliver
  end
end

#called by
UpdateEmailJob.perform_async(<user_id>)
```

Or depending on how up to date things are, try adding the following to to `config/initializers/mandrill_mailer_sidekiq.rb`

```ruby
::MandrillMailer::TemplateMailer.extend(Sidekiq::Extensions::ActionMailer)
```

This should enable you to use this mailer the same way you use ActionMailer.
More info: https://github.com/mperham/sidekiq/wiki/Delayed-Extensions#actionmailer


## Using an interceptor
You can set a mailer interceptor to override any params used when you deliver an e-mail.

Example:

```ruby
MandrillMailer.configure do |config|
  config.interceptor_params = { to: [{ email: "emailtothatwillbeusedinall@emailssent.com", name: "name" }] }
end
```
