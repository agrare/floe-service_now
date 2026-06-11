# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::Cmdb do
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

  describe ".get_ci" do
    let(:params) { {"instance_id" => "dev12345", "sys_id" => "abc123"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "abc123", "name" => "Server01", "ip_address" => "192.168.1.1"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves a CI and returns success" do
        expect(connection).to receive(:get).with("/api/now/table/cmdb_ci/abc123").and_return(response)

        result = described_class.get_ci(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with custom table" do
      let(:params) { {"instance_id" => "dev12345", "sys_id" => "abc123", "table" => "cmdb_ci_server"} }
      let(:response_body) { {"result" => {"sys_id" => "abc123", "name" => "Server01"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves a CI from custom table" do
        expect(connection).to receive(:get).with("/api/now/table/cmdb_ci_server/abc123").and_return(response)

        result = described_class.get_ci(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing sys_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing sys_id" do
        result = described_class.get_ci(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: sys_id")
      end
    end

    context "with missing credentials" do
      let(:secrets) { {} }

      it "returns error for missing username" do
        result = described_class.get_ci(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Credential: username")
      end
    end
  end

  describe ".query_cis" do
    let(:params) { {"instance_id" => "dev12345", "query" => "ip_address=192.168.1.1", "limit" => "10"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => [{"sys_id" => "abc123", "name" => "Server01"}, {"sys_id" => "def456", "name" => "Server02"}]} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "queries CIs and returns success" do
        expect(connection).to receive(:get).with("/api/now/table/cmdb_ci").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.query_cis(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with custom table" do
      let(:params) { {"instance_id" => "dev12345", "table" => "cmdb_ci_server"} }
      let(:response_body) { {"result" => []} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "queries CIs from custom table" do
        expect(connection).to receive(:get).with("/api/now/table/cmdb_ci_server").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.query_cis(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing instance_id" do
      let(:params) { {} }

      it "returns error for missing instance_id" do
        result = described_class.query_cis(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end
  end

  describe ".create_ci" do
    let(:params) do
      {
        "instance_id" => "dev12345",
        "attributes"  => {
          "name"       => "Server01",
          "ip_address" => "192.168.1.1"
        }
      }
    end

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "abc123", "name" => "Server01", "ip_address" => "192.168.1.1"}} }
      let(:response) { instance_double(Faraday::Response, :status => 201, :body => response_body) }

      it "creates a CI and returns success" do
        expect(connection).to receive(:post).with("/api/now/table/cmdb_ci").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.create_ci(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with custom table" do
      let(:params) do
        {
          "instance_id" => "dev12345",
          "table"       => "cmdb_ci_server",
          "attributes"  => {
            "name" => "Server01"
          }
        }
      end
      let(:response_body) { {"result" => {"sys_id" => "abc123"}} }
      let(:response) { instance_double(Faraday::Response, :status => 201, :body => response_body) }

      it "creates a CI in custom table" do
        expect(connection).to receive(:post).with("/api/now/table/cmdb_ci_server").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.create_ci(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing attributes" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing name" do
        result = described_class.create_ci(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: attributes")
      end
    end
  end

  describe ".update_ci" do
    let(:params) do
      {
        "instance_id" => "dev12345",
        "sys_id"      => "abc123",
        "ip_address"  => "192.168.1.2"
      }
    end

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "abc123", "ip_address" => "192.168.1.2"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "updates a CI and returns success" do
        expect(connection).to receive(:patch).with("/api/now/table/cmdb_ci/abc123").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.update_ci(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with custom table" do
      let(:params) do
        {
          "instance_id" => "dev12345",
          "table"       => "cmdb_ci_server",
          "sys_id"      => "abc123",
          "ip_address"  => "192.168.1.2"
        }
      end
      let(:response_body) { {"result" => {"sys_id" => "abc123"}} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "updates a CI in custom table" do
        expect(connection).to receive(:patch).with("/api/now/table/cmdb_ci_server/abc123").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.update_ci(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing sys_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing sys_id" do
        result = described_class.update_ci(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: sys_id")
      end
    end
  end

  describe ".delete_ci" do
    let(:params) { {"instance_id" => "dev12345", "sys_id" => "abc123"} }

    context "with valid parameters" do
      let(:response) { instance_double(Faraday::Response, :status => 204, :body => {}) }

      it "deletes a CI and returns success" do
        expect(connection).to receive(:delete).with("/api/now/table/cmdb_ci/abc123").and_return(response)

        result = described_class.delete_ci(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]["deleted"]).to be true
        expect(result["output"]["sys_id"]).to eq("abc123")
      end
    end

    context "with custom table" do
      let(:params) { {"instance_id" => "dev12345", "table" => "cmdb_ci_server", "sys_id" => "abc123"} }
      let(:response) { instance_double(Faraday::Response, :status => 204, :body => {}) }

      it "deletes a CI from custom table" do
        expect(connection).to receive(:delete).with("/api/now/table/cmdb_ci_server/abc123").and_return(response)

        result = described_class.delete_ci(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing sys_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing sys_id" do
        result = described_class.delete_ci(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: sys_id")
      end
    end
  end

  describe ".get_ci_relationships" do
    let(:params) { {"instance_id" => "dev12345", "sys_id" => "abc123"} }

    context "with valid parameters" do
      let(:ci_response_body) { {"result" => {"sys_id" => "abc123", "name" => "Server01"}} }
      let(:ci_response) { instance_double(Faraday::Response, :status => 200, :body => ci_response_body) }
      let(:rel_response_body) { {"result" => [{"parent" => "abc123", "child" => "def456", "type" => "Runs on::Runs"}]} }
      let(:rel_response) { instance_double(Faraday::Response, :status => 200, :body => rel_response_body) }

      it "retrieves CI relationships and returns success" do
        expect(connection).to receive(:get).with("/api/now/cmdb/instance/cmdb_ci/abc123").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(ci_response)

        expect(connection).to receive(:get).with("/api/now/table/cmdb_rel_ci").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(rel_response)

        result = described_class.get_ci_relationships(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]["sys_id"]).to eq("abc123")
        expect(result["output"]["relationships"]).to eq(rel_response_body["result"])
      end
    end

    context "with missing sys_id" do
      let(:params) { {"instance_id" => "dev12345"} }

      it "returns error for missing sys_id" do
        result = described_class.get_ci_relationships(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: sys_id")
      end
    end
  end

  describe ".create_ci_relationship" do
    let(:params) do
      {
        "instance_id"       => "dev12345",
        "parent_sys_id"     => "abc123",
        "child_sys_id"      => "def456",
        "relationship_type" => "Runs on::Runs"
      }
    end

    context "with valid parameters" do
      let(:response_body) { {"result" => {"sys_id" => "rel123", "parent" => "abc123", "child" => "def456"}} }
      let(:response) { instance_double(Faraday::Response, :status => 201, :body => response_body) }

      it "creates a CI relationship and returns success" do
        expect(connection).to receive(:post).with("/api/now/table/cmdb_rel_ci").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.create_ci_relationship(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with custom connection_strength" do
      let(:params) do
        {
          "instance_id"         => "dev12345",
          "parent_sys_id"       => "abc123",
          "child_sys_id"        => "def456",
          "relationship_type"   => "Runs on::Runs",
          "connection_strength" => "2"
        }
      end
      let(:response_body) { {"result" => {"sys_id" => "rel123"}} }
      let(:response) { instance_double(Faraday::Response, :status => 201, :body => response_body) }

      it "creates a CI relationship with custom strength" do
        expect(connection).to receive(:post).with("/api/now/table/cmdb_rel_ci").and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) }).and_return(response)

        result = described_class.create_ci_relationship(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing parent_sys_id" do
      let(:params) do
        {
          "instance_id"       => "dev12345",
          "child_sys_id"      => "def456",
          "relationship_type" => "Runs on::Runs"
        }
      end

      it "returns error for missing parent_sys_id" do
        result = described_class.create_ci_relationship(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: parent_sys_id")
      end
    end

    context "with missing child_sys_id" do
      let(:params) do
        {
          "instance_id"       => "dev12345",
          "parent_sys_id"     => "abc123",
          "relationship_type" => "Runs on::Runs"
        }
      end

      it "returns error for missing child_sys_id" do
        result = described_class.create_ci_relationship(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: child_sys_id")
      end
    end

    context "with missing relationship_type" do
      let(:params) do
        {
          "instance_id"   => "dev12345",
          "parent_sys_id" => "abc123",
          "child_sys_id"  => "def456"
        }
      end

      it "returns error for missing relationship_type" do
        result = described_class.create_ci_relationship(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: relationship_type")
      end
    end
  end

  describe ".get_ci_classes" do
    let(:params) { {"instance_id" => "dev12345"} }

    context "with valid parameters" do
      let(:response_body) { {"result" => [{"name" => "cmdb_ci_server", "label" => "Server"}, {"name" => "cmdb_ci_computer", "label" => "Computer"}]} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves CI classes and returns success" do
        expect(connection).to receive(:get).with("/api/now/table/sys_db_object").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.get_ci_classes(params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be true
        expect(result["output"]).to eq(response_body["result"])
      end
    end

    context "with limit parameter" do
      let(:params) { {"instance_id" => "dev12345", "limit" => "5"} }
      let(:response_body) { {"result" => []} }
      let(:response) { instance_double(Faraday::Response, :status => 200, :body => response_body) }

      it "retrieves limited CI classes" do
        expect(connection).to receive(:get).with("/api/now/table/sys_db_object").and_yield(double.tap do |req|
          allow(req).to receive(:params).and_return({})
        end).and_return(response)

        result = described_class.get_ci_classes(params, secrets, context)

        expect(result["success"]).to be true
      end
    end

    context "with missing instance_id" do
      let(:params) { {} }

      it "returns error for missing instance_id" do
        result = described_class.get_ci_classes(params, secrets, context)

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Missing Parameter: instance_id")
      end
    end
  end
end
