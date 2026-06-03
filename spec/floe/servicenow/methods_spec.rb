# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::Methods do
  it "inherits from Floe::BuiltinRunner::Methods" do
    expect(described_class.superclass).to eq(Floe::BuiltinRunner::Methods)
  end

  it "is the superclass for Table" do
    expect(Floe::ServiceNow::Table.superclass).to eq(described_class)
  end

  it "is the superclass for ServiceCatalog" do
    expect(Floe::ServiceNow::ServiceCatalog.superclass).to eq(described_class)
  end

  describe ".verify_credentials" do
    it "returns nil for valid credentials" do
      result = described_class.send(:verify_credentials, {"username" => "admin", "password" => "password"})
      expect(result).to be_nil
    end

    it "returns error for missing username" do
      result = described_class.send(:verify_credentials, {"password" => "password"})
      expect(result).to eq("Missing Secret: username")
    end

    it "returns error for missing password" do
      result = described_class.send(:verify_credentials, {"username" => "admin"})
      expect(result).to eq("Missing Secret: password")
    end
  end

  describe ".verify_instance_id" do
    it "returns nil when instance_id is present" do
      result = described_class.send(:verify_instance_id, {"instance_id" => "dev12345"})
      expect(result).to be_nil
    end

    it "returns error when instance_id is missing" do
      result = described_class.send(:verify_instance_id, {})
      expect(result).to eq("Missing Parameter: instance_id")
    end
  end

  describe ".handle_response" do
    it "returns the body for successful responses" do
      response = instance_double(Faraday::Response, :status => 200, :body => {"result" => "ok"})
      expect(described_class.send(:handle_response, response)).to eq("result" => "ok")
    end

    it "raises for authentication failures" do
      response = instance_double(Faraday::Response, :status => 401, :body => {})
      expect { described_class.send(:handle_response, response) }.to raise_error("Authentication failed: Invalid credentials")
    end

    it "raises for missing resources" do
      response = instance_double(Faraday::Response, :status => 404, :body => {})
      expect { described_class.send(:handle_response, response) }.to raise_error("Resource not found")
    end
  end
end
