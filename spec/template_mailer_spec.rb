require "spec_helper"

describe MandrillMailer::TemplateMailer do
  let(:image_path) { '/assets/image.jpg' }
  let(:default_host) { 'localhost:3000' }
  let(:mailer) { described_class.new }
  let(:api_key) { '1237861278' }

  before do
    MandrillMailer.config.api_key = api_key
    MandrillMailer.config.default_url_options = { host: default_host }
    MandrillMailer.config.any_instance.stub(:image_path).and_return(image_path)
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
        mailer.send(:image_path, image).should eq ActionController::Base.asset_path(image)
      end
    end

    context 'Rails does not exist' do
      it 'should raise exception' do
        ->{ subject }.should raise_error
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
    let(:template_content_name) { 'edit' }
    let(:template_content_content) { 'edit_content' }
    let(:from_email) { 'from@email.com' }
    let(:var_name) { 'USER_NAME' }
    let(:var_content) { 'bobert' }
    let(:to_email) { 'bob@email.com' }
    let(:to_name) { 'bob' }

    let(:args) do
      {
        template: 'Email Template',
        subject: "super secret",
        to: {'email' => to_email, 'name' => to_name},
        vars: {
          var_name => var_content
        },
        template_content: {template_content_name => template_content_content},
        headers: {"Reply-To" => "support@email.com"},
        bcc: 'email@email.com',
        tags: ['tag1'],
        google_analytics_domains: ["http://site.com"],
        google_analytics_campaign: '1237423474'
      }
    end

    subject { mailer.mandrill_mail(args) }

    before do
      MandrillMailer::TemplateMailer.default from: from_email
    end

    it 'should return the current class instance' do
      should eq mailer
    end

    it 'should set the template name' do
      subject.template_name.should eq 'Email Template'
    end

    it 'should set the template content' do
      subject.template_content.should eq [{'name' => template_content_name, 'content' => template_content_content}]
    end

    it 'should produce the correct message' do
      subject.message.should eq ({
        "subject" => args[:subject],
        "from_email" => from_email,
        "from_name" => from_email,
        "to" => [{'email' => to_email, 'name' => to_name}],
        "headers" => args[:headers],
        "track_opens" => true,
        "track_clicks" => true,
        "auto_text" => true,
        "url_strip_qs" => true,
        "bcc_address" => args[:bcc],
        "global_merge_vars" => [{"name" => var_name, "content" => var_content}],
        "tags" => args[:tags],
        "google_analytics_domains" => args[:google_analytics_domains],
        "google_analytics_campaign" => args[:google_analytics_campaign]
      })
    end

    it 'should retain data method' do
      subject.data.should eq({
        "key" => MandrillMailer.config.api_key,
        "template_name" => subject.template_name,
        "template_content" => subject.template_content,
        "message" => subject.message,
      })
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
        subject.should eq router.course_url(host: host)
      end

      context 'route helper with an argument' do
        it 'should return the correct route' do
          subject.should eq router.course_url({id: 1, title: 'zombies'}, host: host)
        end
      end
    end

    context 'Rails is not defined' do
      it 'should raise an exception' do
        ->{subject}.should raise_error
      end
    end
  end
end
