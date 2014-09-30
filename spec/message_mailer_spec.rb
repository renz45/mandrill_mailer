require "spec_helper"
require 'base64'

describe MandrillMailer::MessageMailer do
  let(:image_path) { '/assets/image.jpg' }
  let(:default_host) { 'localhost:3000' }
  let(:mailer) { described_class.new }
  let(:api_key) { '1237861278' }

  
  let(:from_email) { 'from@email.com' }
  let(:from_name) { 'Example Name' }
  let(:var_name) { 'USER_NAME' }
  let(:var_content) { 'bobert' }
  let(:var_rcpt_name) { 'USER_INFO' }
  let(:var_rcpt_content) { 'boboblacksheep' }
  let(:to_email) { 'bob@email.com' }
  let(:to_name) { 'bob' }
  let(:attachment_file) { File.read(File.expand_path('spec/support/test_image.png')) }
  let(:attachment_filename) { 'test_image.png' }
  let(:attachment_mimetype) { 'image/png' }

  let(:image_file) { File.read(File.expand_path('spec/support/test_image.png')) }
  let(:image_filename) { 'test_image.png' }
  let(:image_mimetype) { 'image/png' }

  let(:send_at) { Time.utc(2020, 1, 1, 8, 0) }
  let(:bcc) { "bcc@email.com" }

  
  
  let(:message_args) do
    {
      text: "Example text content",
      html: "<p>Example HTML content</p>",
      view_content_link: "http://www.nba.com",
      from: from_email,
      subject: "super secret",
      to: {'email' => to_email, 'name' => to_name},
      preserve_recipients: false,
      vars: {
        var_name => var_content
      },
      recipient_vars: [
        { to_email => { var_rcpt_name => var_rcpt_content } }
      ],
      headers: {"Reply-To" => "support@email.com"},
      bcc: bcc,
      tags: ['tag1'],
      subaccount: "subaccount1",
      google_analytics_domains: ["http://site.com"],
      google_analytics_campaign: '1237423474',
      attachments: [{file: attachment_file, filename: attachment_filename, mimetype: attachment_mimetype}],
      images: [{file: image_file, filename: image_filename, mimetype: image_mimetype}],
      inline_css: true,
      important: true,
      send_at: send_at,
      track_opens: false,
      track_clicks: false,
      url_strip_qs: false
    }
  end

  before do
    MandrillMailer.config.api_key = api_key
    MandrillMailer.config.default_url_options = { host: default_host }
    #MandrillMailer.config.stub(:image_path).and_return(image_path)
    allow(MandrillMailer.config).to receive(:image_path).and_return(image_path)
    
    MandrillMailer::MessageMailer.default from: from_email, from_name: from_name
  end

  
  describe '#mandrill_message_mail' do
    subject { mailer.mandrill_mail(message_args) }



    it 'should not set the html' do
      expect(subject.html).to be_nil
    end

    it 'should not set the text' do
      expect(subject.text).to be_nil
    end
    
    
    it 'should set send_at option' do
      expect(subject.send_at).to eq('2020-01-01 08:00:00')
    end

   

    context "with interceptor" do
      before(:each) do
        @intercepted_params = {
          to: { email: 'interceptedto@test.com', name: 'Mr. Interceptor' },
          tags: ['intercepted-tag'],
          bcc_address: 'interceptedbbc@email.com'
        }
        MandrillMailer.config.interceptor_params = @intercepted_params
      end

      after do
        MandrillMailer.config.interceptor_params = nil
      end

      it "should raise an error if interceptor params is not a Hash" do
        MandrillMailer.config.interceptor_params = "error"
        expect { subject }.to raise_error(MandrillMailer::MessageMailer::InvalidInterceptorParams, "The interceptor_params config must be a Hash")
      end
      
      it 'should produce the correct message' do
        expect(subject.message.to_a - {
          "text" =>  "Example text content",
          "html" => "<p>Example HTML content</p>",
          "view_content_link" =>  "http://www.nba.com",
          "subject" => message_args[:subject],
          "from_email" => from_email,
          "from_name" => from_name,
          "to" => @intercepted_params[:to],
          "headers" => message_args[:headers],
          "important" => message_args[:important],
          "inline_css" => message_args[:inline_css],
          "track_opens" => message_args[:track_opens],
          "track_clicks" => message_args[:track_clicks],
          "auto_text" => true,
          "url_strip_qs" => message_args[:url_strip_qs],
          "preserve_recipients" => false,
          "bcc_address" => @intercepted_params[:bcc_address],
          "global_merge_vars" => [{"name" => var_name, "content" => var_content}],
          "merge_vars" => [{"rcpt" => to_email, "vars" => [{"name" => var_rcpt_name, "content" => var_rcpt_content}]}],
          "tags" => @intercepted_params[:tags],
          "metadata" => message_args[:metadata],
          "subaccount" => message_args[:subaccount],
          "google_analytics_domains" => message_args[:google_analytics_domains],
          "google_analytics_campaign" => message_args[:google_analytics_campaign],
          "attachments" => [{'type' => attachment_mimetype, 'name' => attachment_filename, 'content' => Base64.encode64(attachment_file)}],
          "images" => [{'type' => image_mimetype, 'name' => image_filename, 'content' => Base64.encode64(image_file)}]
        }.to_a).to eq []
      
      end
  
    end
  end
    
    
end
