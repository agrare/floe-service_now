# frozen_string_literal: true

RSpec.describe Floe::ServiceNow do
  describe "module constants" do
    it "defines SCHEME" do
      expect(described_class::SCHEME).to eq("servicenow")
    end

    it "defines SCHEME_PREFIX" do
      expect(described_class::SCHEME_PREFIX).to eq("servicenow://")
    end
  end

  describe ".error!" do
    it "returns error runner context" do
      result = described_class.error!({}, :cause => "Test error")

      expect(result["running"]).to be false
      expect(result["success"]).to be false
      expect(result["output"]["Error"]).to eq("States.TaskFailed")
      expect(result["output"]["Cause"]).to eq("Test error")
    end

    it "accepts custom error type" do
      result = described_class.error!({}, :cause => "Test error", :error => "CustomError")

      expect(result["output"]["Error"]).to eq("CustomError")
    end

    it "merges with existing runner context" do
      context = {"method" => "test_method"}
      result = described_class.error!(context, :cause => "Test error")

      expect(result["method"]).to eq("test_method")
      expect(result["success"]).to be false
    end
  end

  describe ".success!" do
    it "returns success runner context" do
      output = {"sys_id" => "123", "number" => "INC0001"}
      result = described_class.success!({}, :output => output)

      expect(result["running"]).to be false
      expect(result["success"]).to be true
      expect(result["output"]).to eq(output)
    end

    it "merges with existing runner context" do
      context = {"method" => "test_method"}
      result = described_class.success!(context, :output => {"result" => "ok"})

      expect(result["method"]).to eq("test_method")
      expect(result["success"]).to be true
    end
  end

  describe "runner registration" do
    it "registers the servicenow scheme with Floe::Runner" do
      runner = Floe::Runner.for_resource("servicenow://create_incident")
      expect(runner).to be_a(Floe::ServiceNow::Runner)
    end
  end

  describe "integration" do
    let(:runner) { Floe::ServiceNow::Runner.new }
    let(:secrets) do
      {
        "username" => "admin",
        "password" => "password"
      }
    end
    let(:context) { double("context") }

    context "with mocked HTTP responses" do
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Floe::ServiceNow::Table).to receive(:build_connection).and_return(connection)
      end

      it "creates an incident end-to-end" do
        response_body = {"result" => {"sys_id" => "abc123", "number" => "INC0001"}}
        response = instance_double(Faraday::Response, :status => 201, :body => response_body)

        expect(connection).to receive(:post).with("/api/now/table/incident")
                                            .and_yield(double(:body => nil).tap { |req| allow(req).to receive(:body=) })
                                            .and_return(response)

        result = runner.run_async!(
          "servicenow://table/create_incident",
          {"instance_id" => "dev12345", "short_description" => "Test incident"},
          secrets,
          context
        )

        expect(result["method"]).to eq("table/create_incident")
        expect(result["success"]).to be true
        expect(result["output"]["sys_id"]).to eq("abc123")
        expect(runner.running?(result)).to be false
        expect(runner.success?(result)).to be true
        expect(runner.output(result)).to eq(response_body["result"])
      end

      it "handles errors gracefully" do
        response = instance_double(Faraday::Response, :status => 401, :body => {})

        expect(connection).to receive(:post).and_return(response)

        result = runner.run_async!(
          "servicenow://table/create_incident",
          {"instance_id" => "dev12345", "short_description" => "Test incident"},
          secrets,
          context
        )

        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to include("Authentication failed")
        expect(runner.running?(result)).to be false
        expect(runner.success?(result)).to be false
      end
    end
  end
end
