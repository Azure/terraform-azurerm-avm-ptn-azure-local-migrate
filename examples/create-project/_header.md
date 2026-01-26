# Create New Azure Migrate Project

This example demonstrates how to create a new Azure Migrate project using the module.

## Key Features

- Creates a new Azure Migrate project in the specified resource group
- Optionally creates the resource group if it doesn't exist
- Configures the project with appropriate location and tags
- Uses the `create_migrate_project = true` flag to enable project creation

## Prerequisites

- An Azure subscription
- Appropriate permissions to create Azure Migrate projects in the subscription
- A supported Azure region (see variables.tf for the list)

## Important Notes

- Set `create_migrate_project = true` to create a new project
- Set `create_resource_group = true` to create a new resource group (or `false` to use existing)
- If set to `false` (default), the module will query an existing project
- The project name must be unique within the resource group
- Azure Migrate projects are only available in specific regions
- **VM Discovery must be performed from the Azure Portal after project creation**
