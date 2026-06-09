{
  "Comment": "Example workflow to create a Server Configuration Item in ServiceNow CMDB",
  "StartAt": "CreateServerCi",
  "States": {
    "CreateServerCi": {
      "Type": "Task",
      "Resource": "servicenow://cmdb/create_ci",
      "Parameters": {
        "instance_id.$": "$.instance_id",
        "table.$": "$.table",
        "attributes": {
          "name.$": "$.name",
          "sys_class_name.$": "$.table",
          "owned_by": "System Administrator",
          "discovery_source": "Manual via IRE"
        },
        "outbound_relations": [],
        "inbound_relations": []
      },
      "Credentials": {
        "username.$": "$$.Credentials.username",
        "password.$": "$$.Credentials.password"
      },
      "ResultPath": "$.new_server",
      "Next": "GetServerDetails"
    },
    "GetServerDetails": {
      "Type": "Task",
      "Resource": "servicenow://cmdb/get_ci",
      "Parameters": {
        "instance_id.$": "$.instance_id",
        "table.$": "$.table",
        "sys_id.$": "$.new_server.attributes.sys_id"
      },
      "Credentials": {
        "username.$": "$$.Credentials.username",
        "password.$": "$$.Credentials.password"
      },
      "ResultPath": "$.server_details",
      "End": true
    }
  }
}
