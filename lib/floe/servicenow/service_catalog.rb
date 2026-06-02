# frozen_string_literal: true

require "faraday"
require "json"

module Floe
  module ServiceNow
    class ServiceCatalog < Floe::ServiceNow::Methods
      def self.submit_catalog_item(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_submit_catalog_item_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        item_sys_id = params["item_sys_id"]

        begin
          response = connection.post("/api/sn_sc/servicecatalog/items/#{item_sys_id}/order_now") do |req|
            req.body = build_submit_catalog_item_body(params)
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.submit_catalog_item_status!(runner_context)
        runner_context
      end

      def self.get_request(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_request_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        request_id = params["request_id"]

        begin
          response = connection.get("/api/sn_sc/servicecatalog/requests/#{request_id}")
          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.get_request_status!(runner_context)
        runner_context
      end

      def self.get_requested_item(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_requested_item_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        requested_item_id = params["requested_item_id"]

        begin
          response = connection.get("/api/sn_sc/servicecatalog/items/#{requested_item_id}/get_item_summary")
          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.get_requested_item_status!(runner_context)
        runner_context
      end

      private_class_method def self.verify_submit_catalog_item_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: item_sys_id" if params["item_sys_id"].nil?

        nil
      end

      private_class_method def self.verify_request_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: request_id" if params["request_id"].nil?

        nil
      end

      private_class_method def self.verify_requested_item_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: requested_item_id" if params["requested_item_id"].nil?

        nil
      end

      private_class_method def self.build_submit_catalog_item_body(params)
        body = params.except("instance_id", "item_sys_id")
        body["variables"] = params["variables"] if params.key?("variables")
        body
      end
    end
  end
end
