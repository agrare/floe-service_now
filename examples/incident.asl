{
  "Comment": "Example create, resolve, and close a ServiceNow Incident",
  "StartAt": "CreateIncident",
  "States": {
    "CreateIncident": {
      "Type": "Task",
      "Resource": "servicenow://incident/create_incident",
      "Credentials": {
        "username.$": "$$.Credentials.username",
        "password.$": "$$.Credentials.password"
      },
      "ResultPath": "$.incident",
      "Next": "ResolveIncident"
    },
    "ResolveIncident": {
      "Type": "Task",
      "Resource": "servicenow://incident/resolve_incident",
      "Parameters": {
        "instance_id.$": "$.instance_id",
        "sys_id.$": "$.incident.sys_id"
      },
      "ResultPath": "$.incident",
      "Credentials": {
        "username.$": "$$.Credentials.username",
        "password.$": "$$.Credentials.password"
      },
      "Next": "CloseIncident"
    },
    "CloseIncident": {
      "Type": "Task",
      "Resource": "servicenow://incident/close_incident",
      "Parameters": {
        "instance_id.$": "$.instance_id",
        "sys_id.$": "$.incident.sys_id"
      },
      "Credentials": {
        "username.$": "$$.Credentials.username",
        "password.$": "$$.Credentials.password"
      },
      "End": true
    }
  }
}
