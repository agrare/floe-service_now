# Floe::ServiceNow

ServiceNow API integration for [Floe](https://github.com/ManageIQ/floe) workflow engine. This gem provides a Runner and Methods classes that inherit from `Floe::BuiltinRunner::Runner` and `Floe::BuiltinRunner::Methods` to enable ServiceNow operations within Floe workflows.

## Features

- **CRUD Operations**: Create, read, update, and query ServiceNow incidents
- **Service Catalog Operations**: Submit catalog items and retrieve request details
- **CMDB Operations**: Manage Configuration Items (CIs) and their relationships
- **ServiceNow Table API v2**: Uses the standard ServiceNow REST API
- **ServiceNow Service Catalog API**: Uses the Service Catalog REST API
- **ServiceNow CMDB API**: Uses the CMDB REST API for Configuration Management
- **Synchronous Execution**: All operations complete immediately
- **Error Handling**: Comprehensive error handling with detailed error messages
- **Authentication**: Basic authentication via secrets parameter

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'floe-servicenow'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install floe-servicenow
```

## Configuration

### Secrets

ServiceNow operations require authentication credentials passed via the `secrets` parameter:

```json
{
  "username": "your-username",
  "password": "your-password"
}
```

**Security Note**: Never hardcode credentials in your workflow definitions. Use Floe's secrets management features.

## Usage

### Resource URI Format

ServiceNow operations use the `servicenow://` URI scheme with API prefix:

```
servicenow://<api_name>/<method_name>
```

For example:
- `servicenow://table_v2/create_incident` - Create incident using Table API v2
- `servicenow://table_v2/get_incident` - Get incident using Table API v2
- `servicenow://service_catalog/submit_catalog_item` - Submit a catalog item request
- `servicenow://service_catalog/get_request` - Get a catalog request
- `servicenow://service_catalog/get_requested_item` - Get a requested item summary

### Available Methods

#### 1. Create Incident

Creates a new incident in ServiceNow.

**Resource**: `servicenow://table_v2/create_incident`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `short_description` (string): Brief description of the incident

**Optional Parameters**:
- `description` (string): Detailed description
- `urgency` (string): Urgency level (1=High, 2=Medium, 3=Low)
- `impact` (string): Impact level (1=High, 2=Medium, 3=Low)
- `priority` (string): Priority (calculated from urgency and impact if not provided)
- Any other valid incident table fields

**Example**:

```json
{
  "Resource": "servicenow://table_v2/create_incident",
  "Parameters": {
    "instance_id": "dev12345",
    "short_description": "Production server is down",
    "description": "The main production server is not responding to requests",
    "urgency": "1",
    "impact": "1",
    "assignment_group": "Network Support"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "number": "INC0001234",
  "state": "1",
  "short_description": "Production server is down",
  ...
}
```

#### 2. Get Incident

Retrieves a specific incident by sys_id.

**Resource**: `servicenow://table_v2/get_incident`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `sys_id` (string): The unique identifier of the incident

**Example**:

```json
{
  "Resource": "servicenow://table_v2/get_incident",
  "Parameters": {
    "instance_id": "dev12345",
    "sys_id": "abc123def456"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "number": "INC0001234",
  "state": "2",
  "short_description": "Production server is down",
  "work_notes": "Investigating the issue...",
  ...
}
```

#### 3. Update Incident

Updates an existing incident.

**Resource**: `servicenow://table_v2/update_incident`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `sys_id` (string): The unique identifier of the incident

**Optional Parameters**:
- Any valid incident table fields to update

**Example**:

```json
{
  "Resource": "servicenow://table_v2/update_incident",
  "Parameters": {
    "instance_id": "dev12345",
    "sys_id": "abc123def456",
    "state": "2",
    "work_notes": "Server has been restarted and is now responding",
    "assigned_to": "john.doe"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "number": "INC0001234",
  "state": "2",
  "work_notes": "Server has been restarted and is now responding",
  ...
}
```

#### 4. Query Incidents

Queries incidents with optional filters.

**Resource**: `servicenow://table_v2/query_incidents`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`

**Optional Parameters**:
- `query` (string): ServiceNow encoded query string (e.g., "active=true^priority=1")
- `limit` (string): Maximum number of records to return
- `offset` (string): Starting record number for pagination
- `fields` (string): Comma-separated list of fields to return

**Example**:

```json
{
  "Resource": "servicenow://table_v2/query_incidents",
  "Parameters": {
    "instance_id": "dev12345",
    "query": "active=true^priority=1",
    "limit": "10",
    "fields": "number,short_description,state,priority"
  }
}
```

**Response**:

```json
[
  {
    "number": "INC0001234",
    "short_description": "Production server is down",
    "state": "2",
    "priority": "1"
  },
  {
    "number": "INC0001235",
    "short_description": "Database connection timeout",
    "state": "1",
    "priority": "1"
  }
]
```

#### 5. Submit Catalog Item

Submits a Service Catalog item order.

**Resource**: `servicenow://service_catalog/submit_catalog_item`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `item_sys_id` (string): The catalog item sys_id to order

**Optional Parameters**:
- `quantity` (integer): Requested quantity
- `variables` (object): Catalog item variables
- Any other valid order payload fields accepted by the Service Catalog API

**Example**:

```json
{
  "Resource": "servicenow://service_catalog/submit_catalog_item",
  "Parameters": {
    "instance_id": "dev12345",
    "item_sys_id": "060f3afa3731300054b6a3549dbe5d3e",
    "quantity": 1,
    "variables": {
      "requested_for": "john.doe",
      "justification": "Need developer access"
    }
  }
}
```

**Response**:

```json
{
  "request_id": "req123",
  "request_number": "REQ0001",
  ...
}
```

#### 6. Get Request

Retrieves a Service Catalog request.

**Resource**: `servicenow://service_catalog/get_request`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `request_id` (string): The request sys_id

**Example**:

```json
{
  "Resource": "servicenow://service_catalog/get_request",
  "Parameters": {
    "instance_id": "dev12345",
    "request_id": "req123"
  }
}
```

**Response**:

```json
{
  "sys_id": "req123",
  "number": "REQ0001",
  "state": "requested",
  ...
}
```

#### 7. Get Requested Item

Retrieves a requested item summary.

**Resource**: `servicenow://service_catalog/get_requested_item`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `requested_item_id` (string): The requested item sys_id

**Example**:

```json
{
  "Resource": "servicenow://service_catalog/get_requested_item",
  "Parameters": {
    "instance_id": "dev12345",
    "requested_item_id": "ritm123"
  }
}
```

**Response**:

```json
{
  "sys_id": "ritm123",
  "number": "RITM0001",
  "state": "requested",
  ...
}
```

### Complete Workflow Example

```json
{
  "Comment": "ServiceNow Incident Management Workflow",
  "StartAt": "CreateIncident",

### CMDB API Methods

The CMDB (Configuration Management Database) API provides methods for managing Configuration Items (CIs) and their relationships in ServiceNow.

#### 1. Get Configuration Item

Retrieves a specific Configuration Item by sys_id.

**Resource**: `servicenow://cmdb/get_ci`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `sys_id` (string): The unique identifier of the CI

**Optional Parameters**:
- `table` (string): The CMDB table name (defaults to "cmdb_ci" if not specified)

**Example**:

```json
{
  "Resource": "servicenow://cmdb/get_ci",
  "Parameters": {
    "instance_id": "dev12345",
    "sys_id": "abc123def456",
    "table": "cmdb_ci_server"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "name": "Server01",
  "ip_address": "192.168.1.1",
  "operational_status": "1",
  ...
}
```

#### 2. Query Configuration Items

Queries Configuration Items with optional filters.

**Resource**: `servicenow://cmdb/query_cis`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`

**Optional Parameters**:
- `table` (string): The CMDB table name (defaults to "cmdb_ci")
- `query` (string): ServiceNow encoded query string (e.g., "ip_address=192.168.1.1^operational_status=1")
- `limit` (string): Maximum number of records to return
- `offset` (string): Starting record number for pagination
- `fields` (string): Comma-separated list of fields to return

**Example**:

```json
{
  "Resource": "servicenow://cmdb/query_cis",
  "Parameters": {
    "instance_id": "dev12345",
    "table": "cmdb_ci_server",
    "query": "operational_status=1^ip_addressSTARTSWITH192.168",
    "limit": "10",
    "fields": "name,ip_address,operational_status"
  }
}
```

**Response**:

```json
[
  {
    "name": "Server01",
    "ip_address": "192.168.1.1",
    "operational_status": "1"
  },
  {
    "name": "Server02",
    "ip_address": "192.168.1.2",
    "operational_status": "1"
  }
]
```

#### 3. Create Configuration Item

Creates a new Configuration Item in ServiceNow CMDB.

**Resource**: `servicenow://cmdb/create_ci`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `name` (string): Name of the Configuration Item

**Optional Parameters**:
- `table` (string): The CMDB table name (defaults to "cmdb_ci")
- Any other valid CI table fields

**Example**:

```json
{
  "Resource": "servicenow://cmdb/create_ci",
  "Parameters": {
    "instance_id": "dev12345",
    "table": "cmdb_ci_server",
    "name": "Server01",
    "ip_address": "192.168.1.1",
    "operational_status": "1",
    "environment": "Production"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "name": "Server01",
  "ip_address": "192.168.1.1",
  "operational_status": "1",
  ...
}
```

#### 4. Update Configuration Item

Updates an existing Configuration Item.

**Resource**: `servicenow://cmdb/update_ci`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `sys_id` (string): The unique identifier of the CI

**Optional Parameters**:
- `table` (string): The CMDB table name (defaults to "cmdb_ci")
- Any valid CI table fields to update

**Example**:

```json
{
  "Resource": "servicenow://cmdb/update_ci",
  "Parameters": {
    "instance_id": "dev12345",
    "sys_id": "abc123def456",
    "table": "cmdb_ci_server",
    "ip_address": "192.168.1.10",
    "operational_status": "2"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "name": "Server01",
  "ip_address": "192.168.1.10",
  "operational_status": "2",
  ...
}
```

#### 5. Delete Configuration Item

Deletes a Configuration Item from ServiceNow CMDB.

**Resource**: `servicenow://cmdb/delete_ci`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `sys_id` (string): The unique identifier of the CI

**Optional Parameters**:
- `table` (string): The CMDB table name (defaults to "cmdb_ci")

**Example**:

```json
{
  "Resource": "servicenow://cmdb/delete_ci",
  "Parameters": {
    "instance_id": "dev12345",
    "sys_id": "abc123def456",
    "table": "cmdb_ci_server"
  }
}
```

**Response**:

```json
{
  "deleted": true,
  "sys_id": "abc123def456"
}
```

#### 6. Get CI Relationships

Retrieves a Configuration Item and all its relationships (parent and child).

**Resource**: `servicenow://cmdb/get_ci_relationships`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `sys_id` (string): The unique identifier of the CI

**Example**:

```json
{
  "Resource": "servicenow://cmdb/get_ci_relationships",
  "Parameters": {
    "instance_id": "dev12345",
    "sys_id": "abc123def456"
  }
}
```

**Response**:

```json
{
  "sys_id": "abc123def456",
  "name": "Server01",
  "ip_address": "192.168.1.1",
  "relationships": [
    {
      "sys_id": "rel123",
      "parent": "abc123def456",
      "child": "def456ghi789",
      "type": "Runs on::Runs"
    }
  ]
}
```

#### 7. Create CI Relationship

Creates a relationship between two Configuration Items.

**Resource**: `servicenow://cmdb/create_ci_relationship`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`
- `parent_sys_id` (string): The sys_id of the parent CI
- `child_sys_id` (string): The sys_id of the child CI
- `relationship_type` (string): The type of relationship (e.g., "Runs on::Runs", "Depends on::Used by")

**Optional Parameters**:
- `connection_strength` (string): Strength of the connection (1=Weak, 2=Medium, 3=Strong). Defaults to "1"

**Example**:

```json
{
  "Resource": "servicenow://cmdb/create_ci_relationship",
  "Parameters": {
    "instance_id": "dev12345",
    "parent_sys_id": "abc123def456",
    "child_sys_id": "def456ghi789",
    "relationship_type": "Runs on::Runs",
    "connection_strength": "2"
  }
}
```

**Response**:

```json
{
  "sys_id": "rel123",
  "parent": "abc123def456",
  "child": "def456ghi789",
  "type": "Runs on::Runs",
  "connection_strength": "2"
}
```

#### 8. Get CI Classes

Retrieves available Configuration Item classes (types) in the CMDB.

**Resource**: `servicenow://cmdb/get_ci_classes`

**Required Parameters**:
- `instance_id` (string): ServiceNow instance identifier used to build `https://#{instance_id}.service-now.com`

**Optional Parameters**:
- `limit` (string): Maximum number of records to return

**Example**:

```json
{
  "Resource": "servicenow://cmdb/get_ci_classes",
  "Parameters": {
    "instance_id": "dev12345",
    "limit": "20"
  }
}
```

**Response**:

```json
[
  {
    "name": "cmdb_ci_server",
    "label": "Server",
    "super_class": "cmdb_ci_computer"
  },
  {
    "name": "cmdb_ci_computer",
    "label": "Computer",
    "super_class": "cmdb_ci"
  }
]
```


  "States": {
    "CreateIncident": {
      "Type": "Task",
      "Resource": "servicenow://table_v2/create_incident",
      "Parameters": {
        "instance_id": "dev12345",
        "short_description": "Automated alert: High CPU usage",
        "description": "CPU usage exceeded 90% threshold",
        "urgency": "2",
        "impact": "2"
      },
      "Next": "GetIncidentDetails"
    },
    "GetIncidentDetails": {
      "Type": "Task",
      "Resource": "servicenow://table_v2/get_incident",
      "Parameters": {
        "instance_id": "dev12345",
        "sys_id.$": "$.sys_id"
      },
      "Next": "UpdateIncident"
    },
    "UpdateIncident": {
      "Type": "Task",
      "Resource": "servicenow://table_v2/update_incident",
      "Parameters": {
        "instance_id": "dev12345",
        "sys_id.$": "$.sys_id",
        "work_notes": "Automated remediation in progress",
        "state": "2"
      },
      "End": true
    }
  }
}
```

## Error Handling

All methods return standardized error responses following the Floe error format:

```json
{
  "Error": "States.TaskFailed",
  "Cause": "Authentication failed: Invalid credentials"
}
```


### CMDB Workflow Example

```json
{
  "Comment": "ServiceNow CMDB Management Workflow",
  "StartAt": "CreateServer",
  "States": {
    "CreateServer": {
      "Type": "Task",
      "Resource": "servicenow://cmdb/create_ci",
      "Parameters": {
        "instance_id": "dev12345",
        "table": "cmdb_ci_server",
        "name": "WebServer01",
        "ip_address": "192.168.1.100",
        "operational_status": "1",
        "environment": "Production"
      },
      "Next": "CreateDatabase"
    },
    "CreateDatabase": {
      "Type": "Task",
      "Resource": "servicenow://cmdb/create_ci",
      "Parameters": {
        "instance_id": "dev12345",
        "table": "cmdb_ci_database",
        "name": "AppDB01",
        "operational_status": "1"
      },
      "Next": "CreateRelationship"
    },
    "CreateRelationship": {
      "Type": "Task",
      "Resource": "servicenow://cmdb/create_ci_relationship",
      "Parameters": {
        "instance_id": "dev12345",
        "parent_sys_id.$": "$.States.CreateServer.sys_id",
        "child_sys_id.$": "$.States.CreateDatabase.sys_id",
        "relationship_type": "Runs on::Runs",
        "connection_strength": "2"
      },
      "Next": "GetServerWithRelationships"
    },
    "GetServerWithRelationships": {
      "Type": "Task",
      "Resource": "servicenow://cmdb/get_ci_relationships",
      "Parameters": {
        "instance_id": "dev12345",
        "sys_id.$": "$.States.CreateServer.sys_id"
      },
      "End": true
    }
  }
}
```


### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Missing Parameter: instance_id` | ServiceNow instance identifier not provided | Add `instance_id` to parameters |
| `Missing Secret: username` | Username not provided | Add `username` to secrets |
| `Missing Secret: password` | Password not provided | Add `password` to secrets |
| `Missing Parameter: short_description` | Required parameter missing | Add `short_description` to parameters |
| `Missing Parameter: sys_id` | sys_id not provided | Add `sys_id` to parameters |
| `Missing Parameter: item_sys_id` | Catalog item sys_id not provided | Add `item_sys_id` to parameters |
| `Missing Parameter: request_id` | Request sys_id not provided | Add `request_id` to parameters |
| `Missing Parameter: requested_item_id` | Requested item sys_id not provided | Add `requested_item_id` to parameters |
| `Missing Parameter: name` | CI name not provided | Add `name` to parameters |
| `Missing Parameter: parent_sys_id` | Parent CI sys_id not provided | Add `parent_sys_id` to parameters |
| `Missing Parameter: child_sys_id` | Child CI sys_id not provided | Add `child_sys_id` to parameters |
| `Missing Parameter: relationship_type` | Relationship type not provided | Add `relationship_type` to parameters |
| `Authentication failed: Invalid credentials` | Invalid username/password | Verify credentials |
| `Resource not found` | Requested ServiceNow resource does not exist | Verify the supplied identifier is correct |
| `ServiceNow API error: <message>` | ServiceNow API returned an error | Check ServiceNow logs and API documentation |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
bundle exec rspec
```

### Testing Against ServiceNow

To test against a real ServiceNow instance, you'll need:

1. A ServiceNow developer instance (free at https://developer.servicenow.com/)
2. Valid credentials
3. Set environment variables:

```bash
export SERVICENOW_INSTANCE_ID="devXXXXX"
export SERVICENOW_USERNAME="admin"
export SERVICENOW_PASSWORD="your-password"
```

## Architecture

### Class Hierarchy

```
Floe::Runner
  └── Floe::BuiltinRunner::Runner
        └── Floe::ServiceNow::Runner

Floe::BuiltinRunner::Methods (< BasicObject)
  └── Floe::ServiceNow::Methods
```

### Key Components

- **Floe::ServiceNow::Runner**: Handles resource validation, method delegation, and lifecycle management
- **Floe::ServiceNow::Methods**: Implements ServiceNow-specific operations
- **Floe::ServiceNow.error!**: Helper for creating error responses
- **Floe::ServiceNow.success!**: Helper for creating success responses

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/floe-servicenow.

### Development Guidelines

1. Follow existing code patterns from `Floe::BuiltinRunner`
2. Add tests for all new methods
3. Update documentation for new features
4. Ensure all tests pass before submitting PR

## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://opensource.org/licenses/Apache-2.0).

## Related Projects

- [Floe](https://github.com/ManageIQ/floe) - Workflow engine for Ruby
- [ManageIQ](https://github.com/ManageIQ/manageiq) - Open-source management platform

## Support

For issues and questions:
- GitHub Issues: https://github.com/ManageIQ/floe-servicenow/issues
- ManageIQ Community: https://www.manageiq.org/community/
