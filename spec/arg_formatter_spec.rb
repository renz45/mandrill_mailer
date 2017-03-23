require "spec_helper"
require 'base64'

describe MandrillMailer::ArgFormatter do
  subject(:formatter) { described_class }
  let(:api_args) do
    {
      type: "some/type",
      name: 'test',
      content: "testing some test test file"
    }
  end
  let(:encoded_api_args) do
    {
      type: "some/type",
      name: 'test',
      encoded_content: Base64.encode64("testing some test test file")
    }
  end

  let(:file_args) do
    {
      mimetype: "some/type",
      filename: 'test',
      file: "testing some test test file"
    }
  end
  let(:encoded_file_args) do
    {
      mimetype: "some/type",
      filename: 'test',
      encoded_file: Base64.encode64("testing some test test file")
    }
  end


  describe 'attachment_args' do
    context "args are blank" do
      it "returns nil" do
        expect(formatter.attachment_args(nil)).to be_nil
      end
    end

    context "with file syntax" do
      it "formats the correct attachment data" do
        expect(formatter.attachment_args([file_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end

      describe "passing an encoded string" do
        it "formats the correct attachment data" do
          expect(formatter.attachment_args([encoded_file_args])).to eq([{
            'type' => "some/type",
            'name' => 'test',
            'content' => Base64.encode64("testing some test test file")
          }])
        end
      end
    end

    context "with api syntax" do
      it "formats the correct attachment data" do
        expect(formatter.attachment_args([api_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end

      describe "passing an encoded string" do
        it "formats the correct attachment data" do
          expect(formatter.attachment_args([encoded_api_args])).to eq([{
            'type' => "some/type",
            'name' => 'test',
            'content' => Base64.encode64("testing some test test file")
          }])
        end
      end
    end
  end

  describe ".images_args" do
    context "args are blank" do
      it "returns nil" do
        expect(formatter.images_args(nil)).to be_nil
      end
    end

    context "with file syntax" do
      it "formats the correct attachment data" do
        expect(formatter.images_args([file_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end
    end

    context "with api syntax" do
      it "formats the correct attachment data" do
        expect(formatter.images_args([api_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end
    end
  end

  describe ".mandrill_args" do
    context "args are blank" do
      it "returns an empty array" do
        expect(formatter.mandrill_args(nil)).to eq []
      end
    end

    context "args are not blank" do
      let(:arg_name) { 'USER_NAME' }
      let(:arg_value) { 'bob' }

      it 'should convert the args to the correct format' do
        results = formatter.mandrill_args({arg_name => arg_value})
        expect(results).to eq [{'name' => arg_name, 'content' => arg_value}]
      end
    end
  end

  describe ".merge_vars" do
    context "args are blank" do
      it "returns an empty array" do
        expect(formatter.merge_vars(nil)).to eq []
      end
    end
  end

  describe ".rcpt_metadata" do
    context "args are blank" do
      it "returns an empty array" do
        expect(formatter.rcpt_metadata(nil)).to eq []
      end
    end

    context "args are not blank" do
      let(:rcpt) { 'email@email.com' }
      let(:arg_name) { 'USER_NAME' }
      let(:arg_value) { 'bob' }

      it 'should convert the args to the merge_vars format' do
        results = formatter.merge_vars([{rcpt => {arg_name => arg_value}}])
        expect(results).to eq [{'rcpt' => rcpt, 'vars' => [{'name' => arg_name, 'content' => arg_value}]}]
      end
    end
  end

  describe ".boolean" do
    it "typecasts values to a boolean" do
      expect(formatter.boolean(1)).to eq true
      expect(formatter.boolean('1')).to eq true
      expect(formatter.boolean(nil)).to eq false
      expect(formatter.boolean(false)).to eq false
      expect(formatter.boolean(true)).to eq true
    end
  end

  describe ".params" do
    let(:email) { 'bob@email.com' }
    let(:name) { 'bob' }

    context "item is not an array" do
      it "returns an array" do
        results = formatter.params("yay test")
        expect(results).to be_kind_of Array
      end

      context 'with a single email string' do
        it 'should format args to a format mandrill likes' do
          results = formatter.params(email)
          expect(results).to eq [{"email" => email, "name" => email}]
        end
      end

      context 'with a single email/name Hash' do
        it 'should format args to a format mandrill likes' do
          results = formatter.params({"email" => email, "name" => name})
          expect(results).to eq [{"email" => email, "name" => name}]
        end
      end
    end


    context "item is an array" do
      it "returns an array" do
        results = formatter.params(["yay test", "item2"])
        expect(results).to be_kind_of Array
      end

      context 'with a single email string array' do
        it 'should format args to a format mandrill likes' do
          results = formatter.params([email])
          expect(results).to eq [{"email" => email, "name" => email}]
        end
      end

      context 'with a single email/name hash Array' do
        it 'should format args to a format mandrill likes' do
          results = formatter.params([{"email" => email, "name" => name}])
          expect(results).to eq [{"email" => email, "name" => name}]
        end
      end
    end
  end

  describe ".params_item" do
    context "when item is a hash" do
      it "returns the item" do
        sample_hash = {"email" => "test@email.com", "name" => "test"}
        expect(formatter.params_item(sample_hash)).to eq sample_hash
      end
    end

    context "when item is not a hash" do
      it "returns the correctly formatted hash" do
        sample_email = "test@email.com"
        expect(formatter.params_item(sample_email)).to eq({"email" => sample_email, "name" => sample_email})
      end
    end
  end

  describe ".format_messages_api_message_data" do
    it "includes all api values" do
      result = formatter.format_messages_api_message_data({}, {})
      api_values = ["html", "text", "subject", "from_email", "from_name", "to",
                    "headers", "important", "track_opens", "track_clicks", "auto_text",
                    "auto_html", "inline_css", "url_strip_qs", "preserve_recipients",
                    "view_content_link", "bcc_address", "tracking_domain", "signing_domain",
                    "return_path_domain", "merge", "merge_language", "global_merge_vars",
                    "merge_vars", "tags", "subaccount", "google_analytics_domains",
                    "google_analytics_campaign", "metadata", "recipient_metadata",
                    "attachments", "images"]


      api_values.each do |val|
        expect(result.keys.include?(val)).to eq true
      end
    end

    context "merge_language exists" do
      context "merge_language is an accepted merge language" do
        it "does not raise an error" do
          expect { formatter.format_messages_api_message_data({merge_language: "handlebars"}, {}) }.not_to raise_error
        end
      end

      context "merge_language is not an accepted merge language" do
        it "raises an error" do
          expect { formatter.format_messages_api_message_data({merge_language: "not_valid"}, {}) }.to raise_error(MandrillMailer::CoreMailer::InvalidMergeLanguageError)
        end
      end
    end

    context "merge_language does not exist" do
      it "does not raise an error" do
        expect { formatter.format_messages_api_message_data({}, {}) }.not_to raise_error
      end
    end
  end
end
