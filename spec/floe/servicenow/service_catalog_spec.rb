# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::ServiceCatalog do
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

  describe ".submit_catalog_item" do
    let(:params) do
      {
        "instance_id" => "dev12345",
        "item_sys_id" => "item123",
        "quantity"    => 2,
        "variables"   => {
          "requested_for" => "john.doe",
          "justification" => "Need access"
        }
      }
    end

    context "with valid parameters" do
      let(:response_body) { {"result" => {"request_number" => "REQ0001", "request_id" => "req123"}} }
      let(:response) { instance_double(Faraday::Response, :status => 201, :body => response_body) }

      it "submits a catalog item order and returns success" do
        expect(connection).to receive(:post).with("/api/sn_sc/servicecatalog/items/item123/order_now")
                                            .and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) })
                                            .and_return(response)

        result = described_class.submit_catalog_item(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with missing item_sys_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing item_sys_id" do
        result = described_class.submit_catalog_item(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: item_sys_id")
      end
    end

    context "with missing instance_id" do
      let(:params) { {"item_sys_id" => "item123"} }

      it "returns error for missing instance_id" do
        result = described_class.submit_catalog_item(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end
  end

  describe ".get_request" do
    let(:params) { {"instance_id" => "dev12345", "request_id" => "req123"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "req123", "number" => "REQ0001", "state" => "requested"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves a request and returns success" do
        expect(connection).to receive(:get).with("/api/sn_sc/servicecatalog/requests/req123").and_return(response)

        result = described_class.get_request(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with missing request_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing request_id" do
        result = described_class.get_request(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: request_id")
      end
    end
  end

  describe ".get_requested_item" do
    let(:params) { {"instance_id" => "dev12345", "requested_item_id" => "ritm123"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "ritm123", "number" => "RITM0001", "state" => "requested"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves a requested item and returns success" do
        expect(connection).to receive(:get).with("/api/sn_sc/servicecatalog/items/ritm123/get_item_summary").and_return(response)

        result = described_class.get_requested_item(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with missing requested_item_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing requested_item_id" do
        result = described_class.get_requested_item(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: requested_item_id")
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

  describe ".build_submit_catalog_item_body" do
    it "excludes routing params and preserves variables" do
      params = {
        "instance_id" => "dev12345",
        "item_sys_id" => "item123",
        "quantity"    => 1,
        "variables"   => {"requested_for" => "john.doe"}
      }

      result = described_class.send(:build_submit_catalog_item_body, params)

      expect(result).to eq(
        "quantity"  => 1,
        "variables" => {"requested_for" => "john.doe"}
      )
    end
  end
end
