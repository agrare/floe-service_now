# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::Runner do
  let(:runner) { described_class.new }
  let(:secrets) do
    {
      "username" => "admin",
      "password" => "password"
    }
  end
  let(:context) { double("context") }

  describe "::API_CLASSES" do
    it "maps supported APIs to their classes" do
      expect(described_class::API_CLASSES).to eq(
        "table_v2"        => Floe::ServiceNow::TableV2,
        "service_catalog" => Floe::ServiceNow::ServiceCatalog
      )
    end

    it "is frozen" do
      expect(described_class::API_CLASSES).to be_frozen
    end
  end

  describe "#run_async!" do
    context "with valid resource" do
      let(:resource) { "servicenow://table_v2/create_incident" }
      let(:params) { {"instance_id" => "dev12345", "short_description" => "Test incident"} }

      it "delegates to the resolved API class" do
        expect(Floe::ServiceNow::TableV2).to receive(:public_send)
          .with("create_incident", params, secrets, context)
          .and_return({"running" => false, "success" => true, "output" => {"sys_id" => "123"}})

        allow(Floe::ServiceNow::TableV2).to receive(:respond_to?).and_return(false)

        result = runner.run_async!(resource, params, secrets, context)

        expect(result["method"]).to eq("table_v2/create_incident")
        expect(result["success"]).to be true
      end
    end

    context "with invalid resource" do
      let(:resource) { "invalid://create_incident" }
      let(:params) { {} }

      it "raises ArgumentError" do
        expect do
          runner.run_async!(resource, params, secrets, context)
        end.to raise_error(ArgumentError, "Invalid resource")
      end
    end

    context "with undefined method" do
      let(:resource) { "servicenow://table_v2/undefined_method" }
      let(:params) { {} }

      it "returns error response" do
        result = runner.run_async!(resource, params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be false
        expect(result["output"]["Error"]).to eq("States.TaskFailed")
        expect(result["output"]["Cause"]).to include("undefined method")
      end
    end

    context "when method raises an error" do
      let(:resource) { "servicenow://table_v2/create_incident" }
      let(:params) { {"instance_id" => "dev12345", "short_description" => "Test incident"} }

      it "returns error response" do
        allow(Floe::ServiceNow::TableV2).to receive(:public_send)
          .with("create_incident", params, secrets, context)
          .and_raise(StandardError, "Test error")

        allow(Floe::ServiceNow::TableV2).to receive(:respond_to?).and_return(false)

        result = runner.run_async!(resource, params, secrets, context)

        expect(result["running"]).to be false
        expect(result["success"]).to be false
        expect(result["output"]["Cause"]).to eq("Test error")
      end
    end

    context "with service catalog resource" do
      let(:resource) { "servicenow://service_catalog/get_request" }
      let(:params) { {"instance_id" => "dev12345", "request_id" => "req123"} }

      it "delegates to the service catalog API class" do
        expect(Floe::ServiceNow::ServiceCatalog).to receive(:public_send)
          .with("get_request", params, secrets, context)
          .and_return({"running" => false, "success" => true, "output" => {"sys_id" => "req123"}})

        allow(Floe::ServiceNow::ServiceCatalog).to receive(:respond_to?).and_return(false)

        result = runner.run_async!(resource, params, secrets, context)

        expect(result["method"]).to eq("service_catalog/get_request")
        expect(result["success"]).to be true
      end
    end
  end

  describe "#cleanup" do
    let(:runner_context) { {"method" => "table_v2/create_incident"} }

    it "calls cleanup method if it exists" do
      allow(Floe::ServiceNow::TableV2).to receive(:respond_to?)
        .with(:create_incident_cleanup, true)
        .and_return(true)
      expect(Floe::ServiceNow::TableV2).to receive(:send)
        .with(:create_incident_cleanup, runner_context)

      runner.cleanup(runner_context)
    end

    it "does nothing if cleanup method does not exist" do
      allow(Floe::ServiceNow::TableV2).to receive(:respond_to?)
        .with(:create_incident_cleanup, true)
        .and_return(false)

      expect { runner.cleanup(runner_context) }.not_to raise_error
    end

    it "raises ArgumentError if method is nil" do
      expect do
        runner.cleanup({})
      end.to raise_error(ArgumentError)
    end
  end

  describe "#status!" do
    let(:runner_context) { {"method" => "table_v2/create_incident", "running" => true} }

    it "calls status method" do
      allow(Floe::ServiceNow::TableV2).to receive(:respond_to?)
        .with(:create_incident_status!, true)
        .and_return(true)
      expect(Floe::ServiceNow::TableV2).to receive(:send)
        .with(:create_incident_status!, runner_context)

      runner.status!(runner_context)
    end

    it "does nothing if status method does not exist" do
      allow(Floe::ServiceNow::TableV2).to receive(:respond_to?)
        .with(:create_incident_status!, true)
        .and_return(false)

      expect(Floe::ServiceNow::TableV2).not_to receive(:send)

      runner.status!(runner_context)
    end

    it "does nothing if not running" do
      runner_context["running"] = false

      expect(Floe::ServiceNow::TableV2).not_to receive(:send)

      runner.status!(runner_context)
    end

    it "raises ArgumentError if method is nil" do
      expect do
        runner.status!({})
      end.to raise_error(ArgumentError)
    end
  end

  describe "#running?" do
    it "returns the running status" do
      expect(runner.running?({"running" => true})).to be true
      expect(runner.running?({"running" => false})).to be false
    end
  end

  describe "#success?" do
    it "returns the success status" do
      expect(runner.success?({"success" => true})).to be true
      expect(runner.success?({"success" => false})).to be false
    end
  end

  describe "#output" do
    it "returns the output" do
      output = {"sys_id" => "123"}
      expect(runner.output({"output" => output})).to eq(output)
    end
  end
end
