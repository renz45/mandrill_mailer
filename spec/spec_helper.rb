require 'rspec'
require 'mandrill_mailer'
require "mandrill"

require 'pry'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

ActiveJob::Base.queue_adapter = :inline
ActiveJob::Base.logger.level = Logger::WARN

RSpec.configure do |config|
  config.mock_with :rspec
end
