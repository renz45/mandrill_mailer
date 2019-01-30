# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 1.7.1 - 2018-10-06
- Fix rspec matcher: https://github.com/renz45/mandrill_mailer/pull/136

## 1.7.0 - 2018-10-06
- Switch to mandrillus fork of the mandrill-api gem to allow for newer
json gem support

## 1.6.0 - 2017-03-23
- Add support for attaching unencoded content via @brunomperes

## 1.5.0 - 2017-03-20
- Update offline adapter for testing to be more compatible with Rails 5 via @eric1234

## 1.4.0 - 2016-04-28
### Changed
- Update deprecated RSpec failure methods in RSpec helpers.

## 1.3.0 - 2016-03-02
### Added
- Fixed an issue where deliver_later functionality was not working as intended when inheriting from the mailer classes. via @eric1234

## 1.2.0 - 2015-12-22
### Added
- Support for for deliver_later and deliver_now using ActiveJob. via @BenRuns


## 1.1.0 - 2015-10-02
### Added
- Optional RSpec helper (`MandrillMailer::RSpecHelper`) with custom matchers
to simplify testing mailers like:
  - `expect(mailer).to be_from("email@example.com")`
  - `expect(mailer).to have_merge_data('USER_EMAIL' => user.email)`
  - `expect(mailer).to include_merge_var_content(user.email)`
  - `expect(mailer).to have_subject("Hello")`
  - `expect(mailer).to use_template('Example')`
  - `expect(mailer).to send_email_to('email@example.com')`


## 1.0.4 - 2015-09-24
### Added
- Allow default `view_content_link` on Mailer class.

## 1.0.3
- Fix a bug where defaults in merge vars were receiving the correct defaults (credit @kennethkalmer).

## 1.0.1
- Correct regression caused in 1.0.0 that broke defaults in mailers (credit: @etipton).

## 1.0.0
### Changed
- Update manrill_api gem to 1.0.X.
- Change how interceptors work to be more flexible and not overwrite data if needed.
- Make both the template and message mailers compatible with all available attributes in the messages API.

### Removed
- Deprecated `data` method on Mailer objects, replaced with `message`.

## 0.6.1
### Fixed
- Correct a regression introduced in 0.6.0 that caused a TypeError exception.
when no `merge_vars` were provided as arguments to `mandrill_mail`.

## 0.6.0
### Changed
- Allow for default `merge_vars` to be set on the mailer class so that every method inherits them, just like the existing default `from` and `from_name`.

## 0.5.2
### Changed
- Allow the mandrill api gem to be more flexible in the accepted version.
  which allows for the json gem to be updated internally.

## 0.5.0
### Changed
- Made the file attachment and image apis compatible with mandrill api doc syntax.

## 0.4.9
### Added
- Offline support for the `MandrillMailer::Messenger` class. Thanks @arthurtalkgoal.
- Support for the Mandrill Messages api by adding a `MandrillMailer::Messenger` class. Thanks @arthurtalkgoal.

## 0.4.8
### Added
- `to=` setter to template mailer.

## 0.4.7
### Changed
- Reworked how defaults were stored so that they are accessible when being extended.

## 0.4.6
### Added
- Support for images array of embedded images.

## 0.4.5
### Fixed
- Declare `mandrill-api` gem as a runtime dependency to prevent load errors.

## 0.4.4
### Added
- Added `to`, `from` and `bcc` getters to `TemplateMailer` (@renz45).
- Documented how to use the gem with Sidekiq (@elado, @renz45).
- Documented fallback to Mandrill default subject on `mandrill_mail` subject (@Advocation).

### Fixed
- Fix `respond_to` method as it doesn't follow the way standard Ruby respond_to behaves (@tpaktop).

## 0.4.3
### Added
- Look at deliveries for offline testing.
- Intercept emails before they are sent in the config (see the specs for more info).

## 0.4.1
### Added
- Subaccount parameter.

## 0.4.0
### Changed
- Default setting for preserve_recipients no longer defaults to true. Bumping a minor version since this might have been assumed to be default and not set by some.

## 0.3.8
### Added
- This change log.


[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.6.0...HEAD
