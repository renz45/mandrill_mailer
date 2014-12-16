require "spec_helper"
require 'base64'

describe MandrillMailer::CoreMailer do
  subject(:core_mailer) { described_class }

  let(:file_args) do
    {
      mimetype: "some/type",
      filename: 'test',
      file: "testing some test test file"
    }
  end

  let(:api_args) do
    {
      type: "some/type",
      name: 'test',
      content: "testing some test test file"
    }
  end


  describe 'protected#mandrill_attachment_args' do
    context "with file syntax" do
      it "formats the correct attachment data" do
        expect(core_mailer.new.send(:mandrill_attachment_args, [file_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end
    end

    context "with api syntax" do
      it "formats the correct attachment data" do
        expect(core_mailer.new.send(:mandrill_attachment_args, [api_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end
    end
  end

  describe '#mandrill_images_args' do
    context "with file syntax" do
      it "formats the correct attachment data" do
        expect(core_mailer.new.send(:mandrill_attachment_args, [file_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end
    end

    context "with api syntax" do
      it "formats the correct attachment data" do
        expect(core_mailer.new.send(:mandrill_attachment_args, [api_args])).to eq([{
          'type' => "some/type",
          'name' => 'test',
          'content' => Base64.encode64("testing some test test file")
        }])
      end
    end
  end
end
