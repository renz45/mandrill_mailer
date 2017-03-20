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

    it "applies defaults" do
      default_from = "default name"
      default_from_email = "default@email.com"
      default_merge_vars = { foo: "bar" }
      default_view_content_link = true

      unique_mailer = Class.new(core_mailer) do
        default from_name: default_from,
                from: default_from_email,
                merge_vars: default_merge_vars,
                view_content_link: default_view_content_link
      end

      # Create a second mailer to make sure we don't get class var pollution
      control_mailer = Class.new(core_mailer) do
        default from_name: "None",
                from: "invalid@email.com"
      end

      new_unique_mailer = unique_mailer.new
      new_unique_mailer.mandrill_mail({})

      expect(new_unique_mailer.message['from_name']).to eq default_from
      expect(new_unique_mailer.message['from_email']).to eq default_from_email
      expect(new_unique_mailer.message['view_content_link']).to eq default_view_content_link

      global_merge_vars = [{ "name" => :foo, "content" => "bar" }]
      expect(new_unique_mailer.message['global_merge_vars']).to eq global_merge_vars
    end

    describe "vars attribute" do
      it "returns the vars" do
        mailer.mandrill_mail(args)
        expect(mailer.message["global_merge_vars"].first.values).to include(var_name)
        expect(mailer.message["global_merge_vars"].first.values).to include(var_content)
      end

      context "when no vars are set" do
        before do
          args.delete(:vars)
        end

        it "doesn't explode" do
          expect { mailer.mandrill_mail(args) }.not_to raise_error
        end
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
        expect{subject}.to raise_error NoMethodError
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
        expect{ subject }.to raise_error NoMethodError
      end
    end
  end

  describe 'defaults' do
    it "doesn't share between different subclasses" do
      klassA = Class.new(core_mailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(core_mailer) do
        default from_name: 'ClassB'
      end

      expect(klassA.defaults[:from_name]).to eq 'ClassA'
      expect(klassB.defaults[:from_name]).to eq 'ClassB'
    end

    it 'uses defaults from the parent class' do
      klassA = Class.new(core_mailer) do
        default from_name: 'ClassA'
      end
      klassB = Class.new(klassA) do
      end

      expect(klassB.defaults[:from_name]).to eq 'ClassA'
    end

    it 'allows overriding defaults from the parent' do
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

  describe "protected#apply_interceptors!" do
    # Clear the interceptor after these tests so we don't get errors elsewhere
    after do
      MandrillMailer.config.interceptor = nil
    end

    context "when interceptor config is a proc" do
      let(:original_email) { "blah@email.com" }
      let(:interceptor_email) { "intercept@email.com" }

      before do
        MandrillMailer.config.interceptor = Proc.new {|obj|
          obj[:to] = interceptor_email
        }
      end

      it "Applies interceptors to object" do
        obj = {to: original_email}
        expect { mailer.send(:apply_interceptors!, obj)}.to change {obj[:to]}.from(original_email).to(interceptor_email)
      end

      it "does not raise error" do
        expect { mailer.send(:apply_interceptors!, {}) }.not_to raise_error
      end
    end

    context "when interceptor config is not a proc" do
      before do
        MandrillMailer.config.interceptor = "not a proc"
      end

      it "raises an error" do
        expect { mailer.send(:apply_interceptors!, {}) }.to raise_error MandrillMailer::CoreMailer::InvalidInterceptorParams
      end
    end
  end
end
