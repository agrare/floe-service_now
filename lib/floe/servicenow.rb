# frozen_string_literal: true

require "floe"
require_relative "servicenow/version"
require_relative "servicenow/methods"
require_relative "servicenow/table_v2"
require_relative "servicenow/service_catalog"
require_relative "servicenow/runner"

module Floe
  module ServiceNow
    SCHEME        = "servicenow"
    SCHEME_PREFIX = "#{SCHEME}://".freeze

    class Error < StandardError; end

    class << self
      def error!(runner_context = {}, cause:, error: "States.TaskFailed")
        runner_context.merge!(
          "running" => false,
          "success" => false,
          "output"  => {"Error" => error, "Cause" => cause}
        )
      end

      def success!(runner_context = {}, output:)
        runner_context.merge!(
          "running" => false,
          "success" => true,
          "output"  => output
        )
      end
    end
  end
end

Floe::Runner.register_scheme(Floe::ServiceNow::SCHEME, -> { Floe::ServiceNow::Runner.new })
