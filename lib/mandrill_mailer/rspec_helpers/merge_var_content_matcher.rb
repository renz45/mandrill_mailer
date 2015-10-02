# Public: Matcher for asserting specific merge vars content contains something.
#
# expected_data - Data to look for in the specified merge var key.
#
# WelcomeMailer is an instance of MandrillMailler::TemplateMailer
#
# let(:user) { FactoryGirl.create(:user) }
# let(:mailer) { WelcomeMailer.welcome_registered(user) }
# it 'has the correct data' do
#   expect(mailer).to include_merge_var_content(user.email)
# end
#
# Returns true or an error message on failure
#
RSpec::Matchers.define :include_merge_var_content do |expected_data|
  match do |actual|
    has_match = false

    matches = merge_vars_from(actual).find do |hash|
      hash['name'] == 'CONTENT'
    end

    has_match = matches['content'].include?(expected_data)

    has_match
  end

  failure_message do |actual|
    <<-MESSAGE.strip_heredoc
    Expected merge variables: #{merge_vars_from(actual).inspect} to include content: #{expected_data}.
  MESSAGE
  end

  failure_message_when_negated do |actual|
    <<-MESSAGE.strip_heredoc
    Expected merge variables: #{merge_vars_from(actual).inspect} to not include content: #{expected_data}.
  MESSAGE
  end

  description do
    "include merge var content: #{expected_data}"
  end

  def merge_vars_from(mailer)
    # Merge vars are in format:
    # [{"name"=>"USER_EMAIL", "content"=>"zoila@homenick.name"},{"name"=>"USER_NAME", "content"=>"Bob"}]
    mailer.message['global_merge_vars']
  end
end
