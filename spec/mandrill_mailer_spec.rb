require "spec_helper"

describe MandrillMailer::TemplateMailer do
  let(:image_path) { '/assets/image.jpg' }
  let(:default_host) { 'localhost:3000' }
  let(:mailer) {described_class.new}
  let(:api_key) { '1237861278' }

  before do
    MandrillMailer.config.api_key = api_key
    MandrillMailer.config.default_url_options = { host: default_host }
    MandrillMailer.config.any_instance.stub(:image_path).and_return(image_path)
  end

  # this only works from within a Rails application
  # describe '#image_url' do
  #   subject { mailer.send(:image_url, 'image.jpg') }

  #   it 'should return the full path to the image' do
  #     should eq "http://#{default_host}#{image_path}"
  #   end
  # end

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

    let(:data) do
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
    subject { mailer.mandrill_mail(data) }

    before do
      MandrillMailer::TemplateMailer.default from: from_email
    end

    it 'should return the current class instance' do
      should eq mailer
    end

    it 'should produce the correct data' do
      mail = MandrillMailer::TemplateMailer.new().mandrill_mail(data)
      mail.data.should eq ({"key" => api_key, 
        "template_name" => data[:template],
        "template_content" => [{'name' => template_content_name, 'content' => template_content_content}],
        "message" => {
          "subject" => data[:subject], 
          "from_email" => from_email, 
          "from_name" => from_email, 
          "to" => [{'email' => to_email, 'name' => to_name}],
          "headers" => data[:headers],
          "track_opens" => true,
          "track_clicks" => true,
          "auto_text" => true,
          "url_strip_qs" => true,
          "bcc_address" => data[:bcc], 
          "global_merge_vars" => [{"name" => var_name, "content" => var_content}],
          "tags" => data[:tags],
          "google_analytics_domains" => data[:google_analytics_domains],
          "google_analytics_campaign" => data[:google_analytics_campaign]
        }
      })
    end
  end
end