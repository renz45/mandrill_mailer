require "spec_helper"
require 'base64'

describe MandrillMailer::CoreMailer do
  subject(:core_mailer) { described_class }

  let(:image_path) { '/assets/image.jpg' }
  let(:default_host) { 'localhost:3000' }
  let(:mailer) { described_class.new }
  let(:api_key) { '1237861278' }

  let(:from_email) { 'from@email.com' }
  let(:to_email) { 'bob@email.com' }
  let(:to_name) { 'bob' }
  let(:bcc) { "bcc@email.com" }
  let(:var_name) { 'USER_NAME' }
  let(:var_content) { 'bobert' }
  let(:var_rcpt_name) { 'USER_INFO' }
  let(:var_rcpt_content) { 'boboblacksheep' }

  let(:attachment_file) { File.read(File.expand_path('spec/support/test_image.png')) }
  let(:attachment_filename) { 'test_image.png' }
  let(:attachment_mimetype) { 'image/png' }
  let(:image_file) { File.read(File.expand_path('spec/support/test_image.png')) }
  let(:image_filename) { 'test_image.png' }
  let(:image_mimetype) { 'image/png' }
  let(:send_at) { Time.utc(2020, 1, 1, 8, 0) }
  let(:bcc) { "bcc@email.com" }

  let(:async) { double(:async) }
  let(:ip_pool) { double(:ip_pool) }

  let(:args) do
    {
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
      async: async,
      ip_pool: ip_pool,
      track_opens: false,
      track_clicks: false,
      url_strip_qs: false
    }
  end

  let(:sample_message) do
    {
      "from_email" => from_email,
      "to" => [{'email' => to_email, 'name' => to_name}],
      "bcc_address" => bcc,
    }
  end

  before do
    MandrillMailer.config.api_key = api_key
    MandrillMailer.config.default_url_options = { host: default_host }
    allow(MandrillMailer.config).to receive(:image_path).and_return(image_path)
  end

  describe "#mandrill_mail" do
    it "applies interceptors to the message" do
      expect(mailer).to receive(:apply_interceptors!)
      mailer.mandrill_mail(args)
    end

    it "calls the mandrill_mail_handler" do
      expect(mailer).to receive(:mandrill_mail_handler)
      mailer.mandrill_mail(args)
    end

    it "sets the mailer message attribute" do
      expect { mailer.mandrill_mail(args) }.to change { mailer.message }.from(nil)
    end

    it "extracts api_options" do
      expect(mailer).to receive(:extract_api_options!).with(args)
      mailer.mandrill_mail(args)
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

      # Unrequire the fake rails class so it doesn't pollute the rest of the tests
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

  describe 'defaults' do
    it 'should not share between different subclasses' do
      klassA = Class.new(core_mailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(core_mailer) do
        default from_name: 'ClassB'
      end

      expect(klassA.defaults[:from_name]).to eq 'ClassA'
      expect(klassB.defaults[:from_name]).to eq 'ClassB'
    end

    it 'should use defaults from the parent class' do
      klassA = Class.new(core_mailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(klassA) do
      end

      expect(klassB.defaults[:from_name]).to eq 'ClassA'
    end

    it 'should allow overriding defaults from the parent' do
      klassA = Class.new(core_mailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(klassA) do
        default from_name: 'ClassB'
      end

      expect(klassB.defaults[:from_name]).to eq 'ClassB'
    end
  end

  describe "accessor helpers" do
    before do
      allow(mailer).to receive(:message).and_return(sample_message)
    end

    describe "#from" do
      it "returns the from email" do
        expect(mailer.from).to eq from_email
      end
    end

    describe "#to" do
      it "returns the to email data" do
        expect(mailer.to).to eq sample_message['to']
      end
    end

    describe '#to=' do
      it "updates the to email data" do
        sample_email = "something@email.com"
        mailer.to = sample_email
        expect(mailer.to).to eq [{"email" => sample_email, "name" => sample_email}]
      end
    end

    describe "#bcc" do
      it "returns the bcc email/s" do
        expect(mailer.bcc).to eq bcc
      end
    end
  end

  describe '#respond_to' do
    it 'can respond to a symbol' do
      klassA = Class.new(core_mailer) do
        def test_method

        end
      end

      expect(klassA).to respond_to('test_method')
    end
    it 'can respond to a string' do
      klassA = Class.new(core_mailer) do
        def test_method

        end
      end

      expect(klassA).to respond_to('test_method')
    end
  end

  describe "protected#extract_api_options!" do
    it "sets the required api options associated with the messages api" do
      results = mailer.send(:extract_api_options!, args)
      expect(mailer.send_at).to eq('2020-01-01 08:00:00')
      expect(mailer.ip_pool).to eq ip_pool
      expect(mailer.async).to eq async
    end
  end

  describe "protected#format_messages_api_message_data" do
    it "returns the common data associated with the messages api"
  end

  describe "protected#apply_interceptors!" do
    it "Applies interceptors to object"
  #   context "with interceptor" do
  #     before(:each) do
  #       @intercepted_params = {
  #         to: [{ email: 'interceptedto@test.com', name: 'Mr. Interceptor' }],
  #         tags: ['intercepted-tag'],
  #         bcc_address: 'interceptedbbc@email.com'
  #       }
  #       MandrillMailer.config.interceptor_params = @intercepted_params
  #     end
  #
  #     after do
  #       MandrillMailer.config.interceptor_params = nil
  #     end
  #
  #     it "should raise an error if interceptor params is not a Hash" do
  #       MandrillMailer.config.interceptor_params = "error"
  #       expect { subject }.to raise_error(MandrillMailer::TemplateMailer::InvalidInterceptorParams, "The interceptor_params config must be a Hash")
  #     end
  #
  #     it 'should produce the correct message' do
  #       expect(subject.message).to eq ({
  #         "subject" => args[:subject],
  #         "from_email" => from_email,
  #         "from_name" => from_name,
  #         "to" => @intercepted_params[:to],
  #         "headers" => args[:headers],
  #         "important" => args[:important],
  #         "inline_css" => args[:inline_css],
  #         "track_opens" => args[:track_opens],
  #         "track_clicks" => args[:track_clicks],
  #         "auto_text" => true,
  #         "url_strip_qs" => args[:url_strip_qs],
  #         "preserve_recipients" => false,
  #         "bcc_address" => @intercepted_params[:bcc_address],
  #         "merge_language" => args[:merge_language],
  #         "global_merge_vars" => [{"name" => var_name, "content" => var_content}],
  #         "merge_vars" => [{"rcpt" => to_email, "vars" => [{"name" => var_rcpt_name, "content" => var_rcpt_content}]}],
  #         "tags" => @intercepted_params[:tags],
  #         "metadata" => args[:metadata],
  #         "subaccount" => args[:subaccount],
  #         "google_analytics_domains" => args[:google_analytics_domains],
  #         "google_analytics_campaign" => args[:google_analytics_campaign],
  #         "attachments" => [{'type' => attachment_mimetype, 'name' => attachment_filename, 'content' => Base64.encode64(attachment_file)}],
  #         "images" => [{'type' => image_mimetype, 'name' => image_filename, 'content' => Base64.encode64(image_file)}]
  #       })
  #     end
  #   end
  # end
  end
end
