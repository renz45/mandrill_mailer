require "spec_helper"

describe MandrillMailer::MessageMailer do
  let(:mailer) { described_class.new }
  let(:api_key) { '1237861278' }

  before do
    MandrillMailer.config.api_key = api_key
  end

  describe "#deliver" do
    let(:async) { double(:async) }
    let(:ip_pool) { double(:ip_pool) }
    let(:send_at) { double(:send_at) }
    let(:message) { double(:message) }

    it "calls the messages api with #send" do
      mailer.async = async
      mailer.ip_pool = ip_pool
      mailer.send_at = send_at
      mailer.message = message

      expect_any_instance_of(Mandrill::Messages).to receive(:send).with(message, async, ip_pool, send_at)
      mailer.deliver
    end
  end
end
