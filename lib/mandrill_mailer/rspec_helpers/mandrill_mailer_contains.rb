# frozen_string_literal: true
#
# Public: Matcher for asserting :template_name, receiver_email - :to, and optional global variables
#
# WelcomeMailer is an instance of MandrillMailler::TemplateMailer
#
# mail = MandrillMailer.deliveries.last
#
# expect(mail).to be_mandrill_email(
#   template_name: 'user-registered-for-event',
#   to: 'user@mail.com'
# )
#
#  expect(MandrillMailer.deliveries).to include(
#    mandrill_email(
#      template_name: 'user-registered-for-event',
#      to: 'first_user@test.com'
#    ),
#    mandrill_email(
#      template_name: 'send-invitation-to-user',
#      to: 'joe@doe.com'
#    ),
#    mandrill_email(
#      template_name: 'send-invitation-to-user',
#      to: 'rejected@user.com'
#    ),
#    mandrill_email(
#      template_name: 'send-invitation-and-paid',
#      to: 'simon@templar.com'
#    ),
#  )
# expect(mailer).to be_mandrill_email(
#  template_name: 'user-registered-for-event',
#  to: 'joe@doe.example',
#  global_variables: {
#    'FNAME' => 'John',
#    'EVENT_TITLE' => 'Super Series',
#    'EVENT_HREF' => event_url(event, auth_token: auth_token, host: host),
#    'EVENTS_URL' => city_url(event.city, auth_token: auth_token, host: host),
#    'START_TIME' => '10:45am EST / 7:45am PST',
#    'VENUE' => 'Midtown Venue',
#    'START_DATE' => 'Wednesday, 01/10/2018',
#    'NEXT_EVENT_DATE' => nil,
#    'MEMBER_FULL_NAME' => 'John Gates',
#    'MEMBER_EMAIL' => 'joe@doe.example'
#  }
#)
#
RSpec::Matchers.define :mandrill_email do |expected|
  class MailerContains < RSpec::Matchers::BuiltIn::BaseMatcher
    attr_reader :errors
    
    def initialize(expected, actual)
      @expected = expected
      @actual = actual
      @errors = []
    end
    
    def self.check(expected, actual)
      new(expected, actual).check
    end
    
    def check
      @errors << not_match_template_name if actual.template_name != expected.fetch(:template_name)
      @errors << not_match_receiver if actual.message['to'].first['email'] != expected.fetch(:to)
      check_global_variables if expected[:global_variables].present?
      self
    end
    
    def check_global_variables
      expected_global_variables = expected.fetch(:global_variables)
      @errors << variable_missing if (expected_global_variables.to_a - actual_global_variables.to_a).any?
    end
    
    def actual_global_variables
      actual.message['global_merge_vars'].map(&:values).to_h
    end
    
    def variable_missing
      "Global variables missing. Expected: #{expected.fetch(:global_variables)}, got: #{actual_global_variables}" + differ.diff_as_object(expected.fetch(:global_variables), actual_global_variables)
    end
    
    def not_match_template_name
      "Template name doesn't match. Expected: #{expected.fetch(:template_name)}, got: #{actual.template_name}" + differ.diff_as_string(expected.fetch(:template_name), actual.template_name)
    end
    
    def not_match_receiver
      "Receiver doesn't match. Expected: #{expected.fetch(:to)}, got: #{actual.message['to'].first['email']}" + differ.diff_as_string(expected.fetch(:to), actual.message['to'].first['email'])
    end
    
    def differ
      RSpec::Support::Differ.new(object_preparer: ->(object) { RSpec::Matchers::Composable.surface_descriptions_in(object) }, color: RSpec::Matchers.configuration.color?
      )
    end
    
    private
    
    attr_reader :expected, :actual
  end
  
  match do |actual|
    matcher = MailerContains.check(expected, actual)
    if matcher.errors.present?
      @failure_message = matcher.errors.join("\n")
      return false
    end

    true
  end

  failure_message do
    @failure_message
  end
end

RSpec::Matchers.alias_matcher :be_mandrill_email, :mandrill_email
