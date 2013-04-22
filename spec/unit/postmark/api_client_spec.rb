require 'spec_helper'

describe Postmark::ApiClient do

  let(:api_key) { "provided-api-key" }
  let(:max_retries) { 42 }

  let(:api_client) { Postmark::ApiClient.new(api_key) }
  subject { api_client }

  context "attr readers" do
    it { should respond_to(:http_client) }
    it { should respond_to(:max_retries) }
  end

  context "when it's created without options" do

    its(:max_retries) { should eq 3 }

  end

  context "when it's created with user options" do

    subject { Postmark::ApiClient.new(api_key, :max_retries => max_retries,
                                               :foo => :bar)}

    its(:max_retries) { should eq max_retries }

    it 'passes other options to HttpClient instance' do
      Postmark::HttpClient.should_receive(:new).with(api_key, :foo => :bar)
      subject.should be
    end

  end

  describe "#deliver_message" do

    let(:email) { {"From" => "admin@wildbit.com"} }
    let(:email_json) { JSON.dump(email) }
    let(:message) { mock(:to_postmark_hash => email) }
    let(:http_client) { subject.http_client }

    it 'turns message into a JSON document and posts it to /email' do
      http_client.should_receive(:post).with('email', email_json)
      subject.deliver_message(message)
    end

    it "should retry 3 times" do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post)
      expect { subject.deliver_message(message) }.not_to raise_error
    end

    it "should retry on timeout" do
      http_client.should_receive(:post).and_raise(Timeout::Error)
      http_client.should_receive(:post)
      expect { subject.deliver_message(message) }.not_to raise_error
    end

  end

  describe "#deliver_messages" do

    let(:email) { {"From" => "admin@wildbit.com"} }
    let(:emails) { [email, email, email] }
    let(:emails_json) { JSON.dump(emails) }
    let(:message) { mock(:to_postmark_hash => email) }
    let(:http_client) { subject.http_client }

    it 'turns array of messages into a JSON document and posts it to /email/batch' do
      http_client.should_receive(:post).with('email/batch', emails_json)
      subject.deliver_messages([message, message, message])
    end

    it "should retry 3 times" do
      2.times do
        http_client.should_receive(:post).and_raise(Postmark::InternalServerError)
      end
      http_client.should_receive(:post)
      expect { subject.deliver_messages([message, message, message]) }.not_to raise_error
    end

    it "should retry on timeout" do
      http_client.should_receive(:post).and_raise(Timeout::Error)
      http_client.should_receive(:post)
      expect { subject.deliver_messages([message, message, message]) }.not_to raise_error
    end

  end

  describe "#delivery_stats" do
    let(:http_client) { subject.http_client }

    it 'requests data at /deliverystats' do
      http_client.should_receive(:get).with("deliverystats")
      subject.delivery_stats
    end
  end

  describe "#get_bounces" do
    let(:http_client) { subject.http_client }
    let(:options) { {:foo => :bar} }

    it 'requests data at /deliverystats' do
      http_client.should_receive(:get).with("bounces", options)
      subject.get_bounces(options)
    end
  end

  describe "#get_bounced_tags" do
    let(:http_client) { subject.http_client }

    it 'requests data at /bounces/tags' do
      http_client.should_receive(:get).with("bounces/tags")
      subject.get_bounced_tags
    end
  end

  describe "#get_bounce" do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'requests a single bounce by ID at /bounces/:id' do
      http_client.should_receive(:get).with("bounces/#{id}")
      subject.get_bounce(id)
    end
  end

  describe "#dump_bounce" do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'requests a specific bounce data at /bounces/:id/dump' do
      http_client.should_receive(:get).with("bounces/#{id}/dump")
      subject.dump_bounce(id)
    end
  end

  describe "#activate_bounce" do
    let(:http_client) { subject.http_client }
    let(:id) { 42 }

    it 'activates a specific bounce by sending a PUT request to /bounces/:id/activate' do
      http_client.should_receive(:put).with("bounces/#{id}/activate")
      subject.activate_bounce(id)
    end
  end

end