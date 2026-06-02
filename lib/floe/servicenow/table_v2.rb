# frozen_string_literal: true

require "faraday"
require "json"

module Floe
  module ServiceNow
    class TableV2 < Floe::ServiceNow::Methods
      # Create a new incident in ServiceNow
      def self.create_incident(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_create_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)

        begin
          response = connection.post("/api/now/table/incident") do |req|
            req.body = params.except("instance_id")
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.create_incident_status!(runner_context)
        runner_context
      end

      # Get an incident by sys_id
      def self.get_incident(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_get_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        sys_id = params["sys_id"]

        begin
          response = connection.get("/api/now/table/incident/#{sys_id}")
          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.get_incident_status!(runner_context)
        runner_context
      end

      # Update an existing incident
      def self.update_incident(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_update_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        sys_id = params["sys_id"]

        begin
          response = connection.patch("/api/now/table/incident/#{sys_id}") do |req|
            req.body = params.except("sys_id", "instance_id")
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.update_incident_status!(runner_context)
        runner_context
      end

      # Query incidents with optional filters
      def self.query_incidents(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_instance_id(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)

        begin
          response = connection.get("/api/now/table/incident") do |req|
            req.params["sysparm_query"] = params["query"] if params["query"]
            req.params["sysparm_limit"] = params["limit"] if params["limit"]
            req.params["sysparm_offset"] = params["offset"] if params["offset"]
            req.params["sysparm_fields"] = params["fields"] if params["fields"]
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.query_incidents_status!(runner_context)
        runner_context
      end

      # List available tables
      def self.list_tables(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_instance_id(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)

        begin
          response = connection.get("/api/now/table/sys_db_object") do |req|
            req.params["sysparm_query"] = params["query"] if params["query"]
            req.params["sysparm_limit"] = params["limit"] if params["limit"]
            req.params["sysparm_offset"] = params["offset"] if params["offset"]
            req.params["sysparm_fields"] = params["fields"] if params["fields"]
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      private_class_method def self.list_tables_status!(runner_context)
        runner_context
      end

      # Verify parameters for create_incident
      private_class_method def self.verify_create_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: short_description" if params["short_description"].nil?

        nil
      end

      # Verify parameters for get_incident
      private_class_method def self.verify_get_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: sys_id" if params["sys_id"].nil?

        nil
      end

      # Verify parameters for update_incident
      private_class_method def self.verify_update_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: sys_id" if params["sys_id"].nil?

        nil
      end
    end
  end
end
