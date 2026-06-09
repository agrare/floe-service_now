# frozen_string_literal: true

require "faraday"
require "json"

module Floe
  module ServiceNow
    class Cmdb < Floe::ServiceNow::Methods
      # Get a Configuration Item (CI) by sys_id
      def self.get_ci(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_get_ci_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        table = params["table"] || "cmdb_ci"
        sys_id = params["sys_id"]

        begin
          response = connection.get("/api/now/cmdb/instance/#{table}/#{sys_id}")
          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Query Configuration Items with optional filters
      def self.query_cis(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_query_cis_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        table = params["table"] || "cmdb_ci"

        begin
          response = connection.get("/api/now/cmdb/instance/#{table}") do |req|
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

      # Create a new Configuration Item
      def self.create_ci(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_create_ci_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        table = params["table"] || "cmdb_ci"

        begin
          response = connection.post("/api/now/cmdb/instance/#{table}") do |req|
            req.body = params.except("instance_id", "table")
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Update an existing Configuration Item
      def self.update_ci(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_update_ci_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        table = params["table"] || "cmdb_ci"
        sys_id = params["sys_id"]

        begin
          response = connection.patch("/api/now/cmdb/instance/#{table}/#{sys_id}") do |req|
            req.body = params.except("sys_id", "instance_id", "table")
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Delete a Configuration Item
      def self.delete_ci(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_delete_ci_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        table = params["table"] || "cmdb_ci"
        sys_id = params["sys_id"]

        begin
          response = connection.delete("/api/now/cmdb/instance/#{table}/#{sys_id}")
          handle_response(response)
          ServiceNow.success!({}, :output => {"deleted" => true, "sys_id" => sys_id})
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Get CI relationships
      def self.get_ci_relationships(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_get_ci_relationships_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)
        sys_id = params["sys_id"]

        begin
          response = connection.get("/api/now/cmdb/instance/cmdb_ci/#{sys_id}") do |req|
            req.params["sysparm_display_value"] = "true"
            req.params["sysparm_exclude_reference_link"] = "true"
          end

          result = handle_response(response)

          # Get relationships
          relationships_response = connection.get("/api/now/table/cmdb_rel_ci") do |req|
            req.params["sysparm_query"] = "parent=#{sys_id}^ORchild=#{sys_id}"
            req.params["sysparm_display_value"] = "true"
          end

          relationships_result = handle_response(relationships_response)

          output = result["result"].merge("relationships" => relationships_result["result"])
          ServiceNow.success!({}, :output => output)
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Create a CI relationship
      def self.create_ci_relationship(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_create_ci_relationship_params(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)

        begin
          response = connection.post("/api/now/table/cmdb_rel_ci") do |req|
            req.body = {
              "parent"              => params["parent_sys_id"],
              "child"               => params["child_sys_id"],
              "type"                => params["relationship_type"],
              "connection_strength" => params["connection_strength"] || "1"
            }
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Get CI classes (types)
      def self.get_ci_classes(params, secrets, _context)
        error = verify_credentials(secrets)
        return ServiceNow.error!({}, :cause => error) if error

        error = verify_instance_id(params)
        return ServiceNow.error!({}, :cause => error) if error

        connection = build_connection(params, secrets)

        begin
          response = connection.get("/api/now/table/sys_db_object") do |req|
            req.params["sysparm_query"] = "nameSTARTSWITHcmdb_ci"
            req.params["sysparm_fields"] = "name,label,super_class"
            req.params["sysparm_limit"] = params["limit"] if params["limit"]
          end

          result = handle_response(response)
          ServiceNow.success!({}, :output => result["result"])
        rescue => err
          ServiceNow.error!({}, :cause => err.to_s)
        end
      end

      # Verify parameters for get_ci
      private_class_method def self.verify_get_ci_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: sys_id"      if params["sys_id"].nil?

        nil
      end

      # Verify parameters for query_cis
      private_class_method def self.verify_query_cis_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?

        nil
      end

      # Verify parameters for create_ci
      private_class_method def self.verify_create_ci_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: attributes"  if params["attributes"].nil?

        nil
      end

      # Verify parameters for update_ci
      private_class_method def self.verify_update_ci_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: sys_id"      if params["sys_id"].nil?

        nil
      end

      # Verify parameters for delete_ci
      private_class_method def self.verify_delete_ci_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: sys_id"      if params["sys_id"].nil?

        nil
      end

      # Verify parameters for get_ci_relationships
      private_class_method def self.verify_get_ci_relationships_params(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?
        return "Missing Parameter: sys_id"      if params["sys_id"].nil?

        nil
      end

      # Verify parameters for create_ci_relationship
      private_class_method def self.verify_create_ci_relationship_params(params)
        return "Missing Parameter: instance_id"       if params["instance_id"].nil?
        return "Missing Parameter: parent_sys_id"     if params["parent_sys_id"].nil?
        return "Missing Parameter: child_sys_id"      if params["child_sys_id"].nil?
        return "Missing Parameter: relationship_type" if params["relationship_type"].nil?

        nil
      end
    end
  end
end
