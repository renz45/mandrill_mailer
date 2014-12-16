# 0.5.0
- [IMPROVEMENT] Made the file attachment and image apis compatible with mandrill api doc syntax

# 0.4.9
- [FEATURE] Added offline support for the MandrillMailer::Messenger class. Thanks @arthurtalkgoal

# 0.4.9
- [FEATURE] Added support for the Mandrill Messages api by adding a MandrillMailer::Messenger class. Thanks @arthurtalkgoal

# 0.4.8
- [IMPROVEMENT] Add a to= setter to the template mailer

# 0.4.7
- [IMPROVEMENT] Reworked how defaults were stored so that they are accessible when being extended

# 0.4.6
- [FEATURE] Added support for images array of embedded images

# 0.4.5
- [BUGFIX] Declare `mandrill-api` gem as a runtime dependency to prevent load errors.

# 0.4.4
- [FEATURE] Added `to`, `from` and `bcc` getters to `TemplateMailer`. (@renz45)
- [IMPROVEMENT] Fixes respond_to method as it doesn't follow the way standard ruby respond_to behaves. (@tpaktop)
- [DOCS] Documented how to use the gem with Sidekiq (@elado, @renz45)
- [DOCS] Documented fallback to Mandrill default subject on `mandrill_mail` subject. (@Advocation)

# 0.4.3
- [FEATURE] Add the ability to look at deliveries for offline testing.

# 0.4.2
- [FEATURE] Add the ability to intercept emails before they are sent in the config (see the specs for more info).

# 0.4.1
- [FEATURE] Add subaccount parameter.

# 0.4.0
- Default setting for preserve_recipients no longer defaults to true. Bumping a minor version since this might have been assumed to be default and not set by some.

# 0.3.8
- Changelog created.
