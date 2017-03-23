require 'base64'

module MandrillMailer
  class ArgFormatter
    ACCEPTED_MERGE_LANGUAGES = ['mailchimp', 'handlebars'].freeze

    def self.attachment_args(args)
      return unless args
      args.map do |attachment|
        attachment.symbolize_keys!
        type = attachment[:mimetype] || attachment[:type]
        name = attachment[:filename] || attachment[:name]
        file = attachment[:file] || attachment[:content]
        encoded_file = attachment[:encoded_file] || attachment[:encoded_content]
        next {"type" => type, "name" => name, "content" => encoded_file} if encoded_file
        next {"type" => type, "name" => name, "content" => Base64.encode64(file)}
      end
    end

    def self.images_args(args)
      return unless args
      attachment_args(args)
    end

    # convert a normal hash into the format mandrill needs
    def self.mandrill_args(args)
      return [] unless args
      args.map do |k,v|
        {'name' => k, 'content' => v}
      end
    end

    def self.merge_vars(args)
      return [] unless args
      args.map do |item|
        rcpt = item.keys[0]
        {'rcpt' => rcpt, 'vars' => mandrill_args(item.fetch(rcpt))}
      end
    end

    def self.rcpt_metadata(args)
      return [] unless args
      args.map do |item|
        rcpt = item.keys[0]
        {'rcpt' => rcpt, 'values' => item.fetch(rcpt)}
      end
    end

    # ensure only true or false is returned given arg
    def self.boolean(arg)
      !!arg
    end

    # handle if to params is an array of either hashes or strings or the single string
    def self.params(to_params)
      if to_params.kind_of? Array
        to_params.map do |p|
          params_item(p)
        end
      else
        [params_item(to_params)]
      end
    end

    # single to params item
    def self.params_item(item)
      if item.kind_of? Hash
        item
      else
        {"email" => item, "name" => item}
      end
    end

    def self.format_messages_api_message_data(args, defaults)
      # If a merge_language attribute is given and it's not one of the accepted
      # languages Raise an error
      if args[:merge_language] && !ACCEPTED_MERGE_LANGUAGES.include?(args[:merge_language])
        raise MandrillMailer::CoreMailer::InvalidMergeLanguageError.new("The :merge_language value `#{args[:merge_language]}`is invalid, value must be one of: #{ACCEPTED_MERGE_LANGUAGES.join(', ')}.")
      end

      {
        "html" => args[:html],
        "text" => args[:text],
        "subject" => args[:subject],
        "from_email" => args[:from] || defaults[:from],
        "from_name" => args[:from_name] || defaults[:from_name] || defaults[:from],
        "to" => params(args[:to]),
        "headers" => args[:headers],
        "important" => boolean(args[:important]),
        "track_opens" => args.fetch(:track_opens, true),
        "track_clicks" => boolean(args.fetch(:track_clicks, true)),
        "auto_text" => boolean(args.fetch(:auto_text, true)),
        "auto_html" => boolean(args[:auto_html]),
        "inline_css" => boolean(args[:inline_css]),
        "url_strip_qs" => boolean(args.fetch(:url_strip_qs, true)),
        "preserve_recipients" => boolean(args[:preserve_recipients]),
        "view_content_link" => boolean(args[:view_content_link] || defaults[:view_content_link]),
        "bcc_address" => args[:bcc],
        "tracking_domain" => args[:tracking_domain],
        "signing_domain" => args[:signing_domain],
        "return_path_domain" => args[:return_path_domain],
        "merge" => boolean(args[:merge]),
        "merge_language" => args[:merge_language],
        "global_merge_vars" => mandrill_args(args[:vars] || args[:global_merge_vars] || defaults[:merge_vars]),
        "merge_vars" => merge_vars(args[:recipient_vars] || args[:merge_vars]),
        "tags" => args[:tags],
        "subaccount" => args[:subaccount],
        "google_analytics_domains" => args[:google_analytics_domains],
        "google_analytics_campaign" => args[:google_analytics_campaign],
        "metadata" => args[:metadata],
        "recipient_metadata" => args[:recipient_metadata],
        "attachments" => attachment_args(args[:attachments]),
        "images" => images_args(args[:images])
      }
    end
  end
end
