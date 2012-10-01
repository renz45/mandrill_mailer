# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mandrill_mailer/version"

Gem::Specification.new do |s|
  s.name        = "mandrill_mailer"
  s.version     = MandrillMailer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Rensel"]
  s.email       = ["adamrensel@codeschool.com"]
  s.homepage    = "https://github.com/renz45/mandrill_mailer"
  s.summary     = %q{Transactional Mailer for Mandrill}
  s.description = %q{Transactional Mailer for Mandrill}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport'
  s.add_dependency 'actionpack'
  s.add_dependency 'mailchimp', '0.0.7.alpha'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'

end
