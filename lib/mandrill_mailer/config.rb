module MandrillMailer
  class Config
    # Public: this enables the api key to be set in an initializer
    #         ex. MandrillMailer.api_key = ENV[MANDRILL_API_KEY]
    #
    # key - Api key for the Mandrill api
    #
    #
    # Returns 
    def self.api_key=(key)
      @@api_key = key
    end

    # Public: Returns the api key
    #
    # Returns the api key
    def self.api_key
      @@api_key || ''
    end

    def self.default_url_options=(options={})
      @@url_options = options
    end

    def self.default_url_options
      @@url_options || {}
    end
  end
end