# frozen_string_literal: true

module Floe
  module ServiceNow
    class Runner < Floe::BuiltinRunner::Runner
      API_CLASSES = {
        "table_v2" => TableV2
      }.freeze

      def run_async!(resource, params, secrets, context)
        raise ArgumentError, "Invalid resource" unless resource&.start_with?(SCHEME_PREFIX)

        method_name = resource.sub(SCHEME_PREFIX, "")
        runner_context = {"method" => method_name}

        begin
          api_class, api_method = resolve_api_method(method_name)
          method_result = api_class.public_send(api_method, params, secrets, context)
          method_result.merge(runner_context)
        rescue NoMethodError
          Floe::ServiceNow.error!(runner_context, :cause => "undefined method [#{method_name}]")
        rescue => err
          Floe::ServiceNow.error!(runner_context, :cause => err.to_s)
        ensure
          cleanup(runner_context)
        end
      end

      def cleanup(runner_context)
        method_name = runner_context["method"]
        raise ArgumentError if method_name.nil?

        api_class, api_method = resolve_api_method(method_name)
        cleanup_method = :"#{api_method}_cleanup"
        return unless api_class.respond_to?(cleanup_method, true)

        api_class.send(cleanup_method, runner_context)
      rescue NoMethodError
        nil
      end

      def status!(runner_context)
        method_name = runner_context["method"]
        raise ArgumentError if method_name.nil?
        return if runner_context["running"] == false

        api_class, api_method = resolve_api_method(method_name)
        api_class.send(:"#{api_method}_status!", runner_context)
      end

      def running?(runner_context)
        runner_context["running"]
      end

      def success?(runner_context)
        runner_context["success"]
      end

      def output(runner_context)
        runner_context["output"]
      end

      private

      def resolve_api_method(method_name)
        api_name, api_method = method_name.split("/", 2)
        raise NoMethodError if api_name.nil? || api_method.nil?

        api_class = self.class::API_CLASSES[api_name]
        raise NoMethodError if api_class.nil?

        [api_class, api_method]
      end
    end
  end
end
