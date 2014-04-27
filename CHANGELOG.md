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
