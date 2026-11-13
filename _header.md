# terraform-azurerm-avm-ptn-azure-local-migrate

> ⚠️ **Preview Version** - This module is currently in preview. Features and APIs may change before the stable release.

This Terraform module provides infrastructure as code (IaC) capabilities for Azure Migrate, enabling automated discovery, replication, and migration of virtual machines to Azure Stack HCI.

## Required location

The `location` input is required for every operation. Set it to the existing Azure Migrate project's region, or choose a supported region when creating a project. Configurations that previously omitted `location` and relied on project-location discovery must provide it when upgrading.
