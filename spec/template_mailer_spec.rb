require "spec_helper"
require 'base64'

describe MandrillMailer::TemplateMailer do
  let(:image_path) { '/assets/image.jpg' }
  let(:default_host) { 'localhost:3000' }
  let(:mailer) { described_class.new }
  let(:api_key) { '1237861278' }

  let(:template_content_name) { 'edit' }
  let(:template_content_content) { 'edit_content' }
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

  let(:args) do
    {
      from: from_email,
      template: 'Email Template',
      subject: "super secret",
      to: {'email' => to_email, 'name' => to_name},
      preserve_recipients: false,
      vars: {
        var_name => var_content
      },
      recipient_vars: [
        { to_email => { var_rcpt_name => var_rcpt_content } }
      ],
      template_content: {template_content_name => template_content_content},
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

    MandrillMailer::TemplateMailer.default from: from_email, from_name: from_name
  end

  describe '#image_path' do
    subject { mailer.image_path('logo.png') }

    context 'Rails exists' do
      let(:image) { 'image.png' }
      let(:host) { 'codeschool.com' }
      let(:router) { Rails.application.routes.url_helpers }

      before do
        # use load instead of require since we have to reload for every test
        mailer.send(:load, 'fake_rails/fake_rails.rb')
        MandrillMailer.config.default_url_options[:host] = host
      end

      # Essentially un-requiring the fake rails class so it doesn't pollute
      # the rest of the tests
      after do
        Rails.unload!
      end

      it 'should return the image url' do
        #mailer.send(:image_path, image).should eq ActionController::Base.asset_path(image)
        expect(mailer.send(:image_path, image)).to eq(ActionController::Base.asset_path(image))
      end
    end

    context 'Rails does not exist' do
      it 'should raise exception' do
        expect{ subject }.to raise_error
      end
    end
  end

  describe '#mandrill_args' do
    let(:arg_name) { 'USER_NAME' }
    let(:arg_value) { 'bob' }

    subject { mailer.send(:mandrill_args, {arg_name => arg_value}) }

    it 'should convert the args to the correct format' do
      should eq [{'name' => arg_name, 'content' => arg_value}]
    end
  end

  describe '#mandrill_rcpt_args' do
    let(:rcpt) { 'email@email.com' }
    let(:arg_name) { 'USER_NAME' }
    let(:arg_value) { 'bob' }

    subject { mailer.send(:mandrill_rcpt_args, [{rcpt => {arg_name => arg_value}}]) }

    it 'should convert the args to the merge_vars format' do
      should eq [{'rcpt' => rcpt, 'vars' => [{'name' => arg_name, 'content' => arg_value}]}]
    end
  end

  describe '#format_boolean' do
    it 'only returns true or false' do
      expect(mailer.send(:format_boolean, 1)).to eq true
      expect(mailer.send(:format_boolean, '1')).to eq true
      expect(mailer.send(:format_boolean, nil)).to eq false
      expect(mailer.send(:format_boolean, false)).to eq false
      expect(mailer.send(:format_boolean, true)).to eq true
    end
  end

  describe '#format_to_params' do
    let(:email) { 'bob@email.com' }
    let(:name) { 'bob' }

    context 'with a single email string' do
      subject { mailer.send(:format_to_params, email) }

      it 'should format args to a format mandrill likes' do
        should eq [{"email" => email, "name" => email}]
      end
    end

    context 'with a single email string array' do
      subject { mailer.send(:format_to_params, [email]) }

      it 'should format args to a format mandrill likes' do
        should eq [{"email" => email, "name" => email}]
      end
    end

    context 'with a single email/name Hash' do
      subject { mailer.send(:format_to_params, {"email" => email, "name" => name}) }

      it 'should format args to a format mandrill likes' do
        should eq [{"email" => email, "name" => name}]
      end
    end

    context 'with a single email/name hash Array' do
      subject { mailer.send(:format_to_params, [{"email" => email, "name" => name}]) }

      it 'should format args to a format mandrill likes' do
        should eq [{"email" => email, "name" => name}]
      end
    end
  end

  describe '#mandrill_mail' do
    subject { mailer.mandrill_mail(args) }

    it 'should return the current class instance' do
      should eq mailer
    end

    it 'should set the template name' do
      expect(subject.template_name).to eq 'Email Template'
    end


    it 'should set the template content' do
      expect(subject.template_content).to eq [{'name' => template_content_name, 'content' => template_content_content}]
    end

    it 'should retain data method' do
      expect(subject.data).to eq({
        "key" => MandrillMailer.config.api_key,
        "template_name" => subject.template_name,
        "template_content" => subject.template_content,
        "message" => subject.message,
        "async" => subject.async,
        "ip_pool" => subject.ip_pool,
        "send_at" => subject.send_at
      })
    end

    it 'should set send_at option' do
      expect(subject.send_at).to eq('2020-01-01 08:00:00')
    end

    context "without interceptor" do
      it 'should produce the correct message' do
        expect(subject.message).to eq ({
          "subject" => args[:subject],
          "from_email" => from_email,
          "from_name" => from_name,
          "to" => [{'email' => to_email, 'name' => to_name}],
          "headers" => args[:headers],
          "important" => args[:important],
          "inline_css" => args[:inline_css],
          "track_opens" => args[:track_opens],
          "track_clicks" => args[:track_clicks],
          "auto_text" => true,
          "url_strip_qs" => args[:url_strip_qs],
          "preserve_recipients" => false,
          "bcc_address" => args[:bcc],
          "merge_language" => args[:merge_language],
          "global_merge_vars" => [{"name" => var_name, "content" => var_content}],
          "merge_vars" => [{"rcpt" => to_email, "vars" => [{"name" => var_rcpt_name, "content" => var_rcpt_content}]}],
          "tags" => args[:tags],
          "metadata" => args[:metadata],
          "subaccount" => args[:subaccount],
          "google_analytics_domains" => args[:google_analytics_domains],
          "google_analytics_campaign" => args[:google_analytics_campaign],
          "attachments" => [{'type' => attachment_mimetype, 'name' => attachment_filename, 'content' => Base64.encode64(attachment_file)}],
          "images" => [{'type' => image_mimetype, 'name' => image_filename, 'content' => Base64.encode64(image_file)}]
        })
      end
    end

    context "with interceptor" do
      before(:each) do
        @intercepted_params = {
          to: [{ email: 'interceptedto@test.com', name: 'Mr. Interceptor' }],
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
        expect { subject }.to raise_error(MandrillMailer::TemplateMailer::InvalidInterceptorParams, "The interceptor_params config must be a Hash")
      end

      it 'should produce the correct message' do
        expect(subject.message).to eq ({
          "subject" => args[:subject],
          "from_email" => from_email,
          "from_name" => from_name,
          "to" => @intercepted_params[:to],
          "headers" => args[:headers],
          "important" => args[:important],
          "inline_css" => args[:inline_css],
          "track_opens" => args[:track_opens],
          "track_clicks" => args[:track_clicks],
          "auto_text" => true,
          "url_strip_qs" => args[:url_strip_qs],
          "preserve_recipients" => false,
          "bcc_address" => @intercepted_params[:bcc_address],
          "merge_language" => args[:merge_language],
          "global_merge_vars" => [{"name" => var_name, "content" => var_content}],
          "merge_vars" => [{"rcpt" => to_email, "vars" => [{"name" => var_rcpt_name, "content" => var_rcpt_content}]}],
          "tags" => @intercepted_params[:tags],
          "metadata" => args[:metadata],
          "subaccount" => args[:subaccount],
          "google_analytics_domains" => args[:google_analytics_domains],
          "google_analytics_campaign" => args[:google_analytics_campaign],
          "attachments" => [{'type' => attachment_mimetype, 'name' => attachment_filename, 'content' => Base64.encode64(attachment_file)}],
          "images" => [{'type' => image_mimetype, 'name' => image_filename, 'content' => Base64.encode64(image_file)}]
        })
      end
    end
  end


  describe 'url helpers in mailer' do
    subject { mailer.send(:course_url) }

    context 'Rails is defined (Rails app)' do
      let(:url) { '/courses/1' }
      let(:host) { 'codeschool.com' }
      let(:router) { Rails.application.routes.url_helpers }

      before do
        # use load since we are loading multiple times
        mailer.send(:load, 'fake_rails/fake_rails.rb')
        MandrillMailer.config.default_url_options[:host] = host
        Rails.application.routes.draw do |builder|
          builder.course_url "#{url}"
        end
      end

      # Essentially un-requiring the fake rails class so it doesn't pollute
      # the rest of the tests
      after do
        Rails.unload!
      end

      it 'should return the correct route' do
        expect(subject).to eq router.course_url(host: host)
      end

      context 'route helper with an argument' do
        it 'should return the correct route' do
          expect(subject).to eq router.course_url({id: 1, title: 'zombies'}, host: host)
        end
      end
    end

    context 'Rails is not defined' do
      it 'should raise an exception' do
        expect{subject}.to raise_error
      end
    end
  end

  describe 'defaults' do
    it 'should not share between different subclasses' do
      klassA = Class.new(MandrillMailer::TemplateMailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(MandrillMailer::TemplateMailer) do
        default from_name: 'ClassB'
      end

      expect(klassA.mandrill_mail({vars: {}}).message['from_name']).to eq 'ClassA'
      expect(klassB.mandrill_mail({vars: {}}).message['from_name']).to eq 'ClassB'
    end

    it 'should use defaults from the parent class' do
      klassA = Class.new(MandrillMailer::TemplateMailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(klassA) do
      end

      expect(klassB.mandrill_mail({vars:{}}).message['from_name']).to eq 'ClassA'
    end

    it 'should allow overriding defaults from the parent' do
      klassA = Class.new(MandrillMailer::TemplateMailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(klassA) do
        default from_name: 'ClassB'
      end

      expect(klassB.mandrill_mail({vars:{}}).message['from_name']).to eq 'ClassB'
    end
  end

  describe '#respond_to' do
    it 'can respond to a symbol' do
      klassA = Class.new(MandrillMailer::TemplateMailer) do
        def test_method

        end
      end

      expect(klassA).to respond_to('test_method')
    end
    it 'can respond to a string' do
      klassA = Class.new(MandrillMailer::TemplateMailer) do
        def test_method

        end
      end

      expect(klassA).to respond_to('test_method')
    end
  end

  describe "#from" do
    subject { mailer.mandrill_mail(args) }

    it "returns the from email" do
      expect(subject.from).to eq from_email
    end
  end

  describe "#to" do
    subject { mailer.mandrill_mail(args) }

    it "returns the to email data" do
      expect(subject.to).to eq [{"email" => to_email, "name" => to_name}]
    end
  end

  describe '#to=' do
    subject { mailer.mandrill_mail(args) }

    it "updates the to email data" do
      subject.to = 'bob@example.com'
      expect(subject.to).to eq [{"email" => "bob@example.com", "name" => "bob@example.com"}]
    end
  end

  describe "#bcc" do
    subject { mailer.mandrill_mail(args) }

    it "returns the bcc email/s" do
      expect(subject.bcc).to eq bcc
    end
  end
end
