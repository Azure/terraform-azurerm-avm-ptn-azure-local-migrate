## Next Steps

After creating the Migrate project:

### 1. Discover VMs from Azure Portal

**Important**: VM discovery should be performed from the Azure Portal, not through Terraform.

1. Navigate to **Azure Migrate** in the Azure Portal
2. Select your project: `saif-project-012626` (or your project name)
3. Click on **Discover, assess and migrate**
4. Follow the portal wizard to:
   - Set up the appliance (VMware or Hyper-V)
   - Configure discovery settings
   - Start discovering VMs from your source environment

### 2. Initialize Replication Infrastructure

Once VMs are discovered, use the `initialize` example to set up replication:

```bash
cd ../initialize
terraform init
terraform apply
```

### 3. Set Up VM Replication

After initialization, use the `replicate` example to start replicating VMs:

```bash
cd ../replicate
terraform init
terraform apply
```

## Clean Up

To remove the created Migrate project and resource group:

```bash
terraform destroy
```

**Note**: This will delete the entire resource group and all resources within it.
