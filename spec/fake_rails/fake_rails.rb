# Public: This fake rails class is used to test things such as the method_missing route proxy
#         and image_url helpers
#
#         Use Rails.unload! to 'unrequire' this class, you should call this after every test
#         which uses it so other tests aren't polluted by having a Rails class defined
#
#         You can define routes to be used in testing by doing:
#
#         Rails.application.routes.draw do |builder|
#           builder.course_url "/course/1"
#         end
#
#         So then sending the course url helper to the mailer will return the desired url.
#
#         In order to use the url helpers, the MandrillMailer.config.default_url_options[:host]
#         option needs to be set. So you can set it to something like:
#
#         MandrillMailer.config.default_url_options[:host] = 'localhost'
#
class Rails
  def self.unload!
    Object.send(:remove_const, :Rails)
    Object.send(:remove_const, :ActionController)
  end
  # Rails.application.routes.url_helpers
  def self.application
    self
  end

  def self.routes
    self
  end

  def self.url_helpers
    @@url_helpers
  end

  def self.draw(&block)
    @@url_helpers = RouteBuilder.new(block)
  end

  def self.default_url_options
    @@url_options ||= {}
  end

  class RouteBuilder
    def initialize(routes_proc)
      routes_proc.call(self)
    end

    def method_missing(method, *args)
      define_singleton_method(method) do |*method_args|
        internal_args = args || ['']
        "http://#{method_args.extract_options![:host]}#{internal_args.first}"
      end
    end
  end
end

# ActionController::Base.helpers.asset_path(image)
module ActionController
  class Base
    def self.helpers
      self
    end

    def self.asset_path(asset)
      "http://#{Rails.default_url_options[:host]}assets/#{asset}"
    end
  end
end