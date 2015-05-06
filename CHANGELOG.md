# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]

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
