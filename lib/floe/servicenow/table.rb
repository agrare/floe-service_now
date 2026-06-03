# frozen_string_literal: true

require "faraday"
require "json"

module Floe
  module ServiceNow
    class Table < Floe::ServiceNow::Methods
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
    end
  end
end
