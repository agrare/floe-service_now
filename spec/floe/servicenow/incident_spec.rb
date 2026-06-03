# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::Incident do
  let(:secrets) do
    {
      "username" => "admin",
      "password" => "password"
    }
  end
  let(:context) { double("context") }
  let(:connection) { instance_double(Faraday::Connection) }

  before do
    allow(described_class).to receive(:build_connection).and_return(connection)
  end

  describe ".create_incident" do
    let(:params) do
      {
        "instance_id"       => "dev12345",
        "short_description" => "Test incident",
        "description"       => "Test description"
      }
    end

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "abc123", "number" => "INC0001"}} }
      let(:response) { instance_double(Faraday::Response, :status => 201, :body => response_body) }

      it "creates an incident and returns success" do
        expect(connection).to receive(:post).with("/api/now/table/incident").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.create_incident(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with missing credentials" do
      let(:secrets) { {} }

      it "returns error for missing username" do
        result = described_class.create_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Secret: username")
      end
    end

    context "with missing parameters" do
      let(:params) { {} }

      it "returns error for missing instance_url" do
        result = described_class.create_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end

    context "with authentication error" do
      let(:response) { instance_double(Faraday::Response, :status => 401, :body => {}) }

      it "returns error for authentication failure" do
        expect(connection).to receive(:post).and_return(response)

        result = described_class.create_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to include("Authentication failed")
      end
    end
  end

  describe ".get_incident" do
    let(:params) { {"instance_id" => "dev12345", "sys_id" => "abc123"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "abc123", "number" => "INC0001", "state" => "1"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves an incident and returns success" do
        expect(connection).to receive(:get).with("/api/now/table/incident/abc123").and_return(response)

        result = described_class.get_incident(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with missing sys_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing sys_id" do
        result = described_class.get_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: sys_id")
      end
    end

    context "with missing instance_id" do
      let(:params) { {"sys_id" => "abc123"} }

      it "returns error for missing instance_id" do
        result = described_class.get_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end

    context "with not found error" do
      let(:response) { instance_double(Faraday::Response, :status => 404, :body => {}) }

      it "returns error for resource not found" do
        expect(connection).to receive(:get).and_return(response)

        result = described_class.get_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to include("Resource not found")
      end
    end
  end

  describe ".update_incident" do
    let(:params) do
      {
        "instance_id" => "dev12345",
        "sys_id"      => "abc123",
        "state"       => "2",
        "work_notes"  => "Working on it"
      }
    end

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "abc123", "state" => "2"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "updates an incident and returns success" do
        expect(connection).to receive(:patch).with("/api/now/table/incident/abc123").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.update_incident(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with missing sys_id" do
      let(:params) { {"instance_id" => "dev12345", "state" => "2"} }

      it "returns error for missing sys_id" do
        result = described_class.update_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: sys_id")
      end
    end

    context "with missing instance_id" do
      let(:params) { {"sys_id" => "abc123", "state" => "2"} }

      it "returns error for missing instance_id" do
        result = described_class.update_incident(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end
  end

  describe ".query_incidents" do
    let(:params) { {"instance_id" => "dev12345", "query" => "active=true", "limit" => "10"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => [{"sys_id" => "abc123"}, {"sys_id" => "def456"}]} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "queries incidents and returns success" do
        expect(connection).to receive(:get).with("/api/now/table/incident").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.query_incidents(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with no query parameters" do
      let(:params) { {"instance_id" => "dev12345"} }
      let(:response_body) { {"result" => []} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "queries all incidents" do
        expect(connection).to receive(:get).with("/api/now/table/incident").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.query_incidents(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing instance_id" do
      let(:params) { {} }

      it "returns error for missing instance_id" do
        result = described_class.query_incidents(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end
  end

  describe ".verify_credentials" do
    it "returns nil for valid credentials" do
      result = described_class.send(:verify_credentials, secrets)
      expect(result).to be_nil
    end

    it "returns error for missing username" do
      secrets.delete("username")
      result = described_class.send(:verify_credentials, secrets)
      expect(result).to eq("Missing Secret: username")
    end

    it "returns error for missing password" do
      secrets.delete("password")
      result = described_class.send(:verify_credentials, secrets)
      expect(result).to eq("Missing Secret: password")
    end
  end
end
