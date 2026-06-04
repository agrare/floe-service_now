# frozen_string_literal: true

require "faraday"
require "json"

module Floe
  module ServiceNow
    class Methods < Floe::BuiltinRunner::Methods
      private_class_method def self.verify_credentials(secrets)
        return "Missing Credentials"          if secrets.nil?
        return "Missing Credential: username" if secrets["username"].nil?
        return "Missing Credential: password" if secrets["password"].nil?

        nil
      end

      private_class_method def self.verify_instance_id(params)
        return "Missing Parameter: instance_id" if params["instance_id"].nil?

        nil
      end

      private_class_method def self.build_connection(params, secrets)
        instance_id = params["instance_id"]
        username = secrets["username"]
        password = secrets["password"]

        ::Faraday.new(
          :url     => "https://#{instance_id}.service-now.com",
          :headers => {
            "Content-Type" => "application/json",
            "Accept"       => "application/json"
          }
        ) do |conn|
          conn.request(:authorization, :basic, username, password)
          conn.request(:json)
          conn.response(:json)
          conn.adapter(::Faraday.default_adapter)
        end
      end

      private_class_method def self.handle_response(response)
        case response.status
        when 200..299
          response.body
        when 401
          raise "Authentication failed: Invalid credentials"
        when 404
          raise "Resource not found"
        else
          error_detail = response.body.dig("error", "detail")
          error_msg    = response.body.dig("error", "message")
          error_msg   += "\n#{error_detail}" if error_msg && error_detail
          error_msg  ||= "HTTP #{response.status}"
          raise "ServiceNow API error: #{error_msg}"
        end
      end
    end
  end
end
