require "spec_helper"

describe MandrillMailer::TemplateMailer do
  let(:mailer) { described_class.new }
  let(:api_key) { '1237861278' }

  let(:template_content_name) { "test_template" }
  let(:template_content_content) {"some testing content"}

  let(:args) do
    {
      template: 'Email Template',
      template_content: {template_content_name => template_content_content}
    }
  end

  before do
    MandrillMailer.config.api_key = api_key
  end

  describe '#mandrill_mail_handler' do
    it 'should set the template name' do
      mailer.mandrill_mail_handler(args)
      expect(mailer.template_name).to eq 'Email Template'
    end

    it 'should set the template content' do
      mailer.mandrill_mail_handler(args)
      expect(mailer.template_content).to eq [{'name' => template_content_name, 'content' => template_content_content}]
    end
  end

  describe "#deliver_now" do
    let(:async) { double(:async) }
    let(:ip_pool) { double(:ip_pool) }
    let(:send_at) { double(:send_at) }
    let(:message) { double(:message) }
    let(:template_name) { double(:template_name) }
    let(:template_content) { double(:template_content) }

    before do
      mailer.async = async
      mailer.ip_pool = ip_pool
      mailer.send_at = send_at
      mailer.message = message
      mailer.template_content = template_content
      mailer.template_name = template_name
    end

    it "calls the messages api with #send_template" do
      expect_any_instance_of(Mandrill::Messages).to receive(:send_template).with(template_name, template_content, message, async, ip_pool, send_at)
      mailer.deliver_now
    end

    it "has an alias deliver" do
      expect_any_instance_of(Mandrill::Messages).to receive(:send_template).with(template_name, template_content, message, async, ip_pool, send_at)
      mailer.deliver
    end
  end
  describe "#deliver_later" do
    let(:async) { false }
    let(:ip_pool) { 1 }
    let(:send_at) { '100'}
    let(:message) { 'message' }
    let(:template_name) { 'fake_template' }
    let(:template_content) { 'content' }

    it "calls the messages api with #send_template" do
      mailer.async = async
      mailer.ip_pool = ip_pool
      mailer.send_at = send_at
      mailer.message = message
      mailer.template_content = template_content
      mailer.template_name = template_name

      expect_any_instance_of(Mandrill::Messages).to receive(:send_template).with(template_name, template_content, message, async, ip_pool, send_at)
      mailer.deliver_later
    end
  end
end
