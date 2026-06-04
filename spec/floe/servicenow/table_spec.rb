# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::Table do
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

  describe ".list_tables" do
    let(:params) { {"instance_id" => "dev12345", "query" => "super_class=NULL", "limit" => "10"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => [{"name" => "incident"}, {"name" => "change_request"}]} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "lists tables and returns success" do
        expect(connection).to receive(:get).with("/api/now/table/sys_db_object").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.list_tables(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with no query parameters" do
      let(:params) { {"instance_id" => "dev12345"} }
      let(:response_body) { {"result" => []} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "lists all tables" do
        expect(connection).to receive(:get).with("/api/now/table/sys_db_object").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.list_tables(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing instance_id" do
      let(:params) { {} }

      it "returns error for missing instance_id" do
        result = described_class.list_tables(params, secrets, context)

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
      expect(result).to eq("Missing Credential: username")
    end

    it "returns error for missing password" do
      secrets.delete("password")
      result = described_class.send(:verify_credentials, secrets)
      expect(result).to eq("Missing Credential: password")
    end
  end
end
