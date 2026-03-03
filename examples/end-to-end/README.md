# End-to-End VM Replication and Migration Example

This example demonstrates a complete migration workflow in a single Terraform configuration:

1. **Replicate** — Start VM replication to Azure Stack HCI
2. **Check Status** — Query the replication state of the protected item
3. **Migrate** — Perform a planned failover once replication is complete

## Usage

### Step 1: Start Replication and Check Status

```bash
terraform init
terraform apply
```

This creates the replication and immediately checks the status. The `replication_status` output shows the current state.

### Step 2: Poll Until Ready

Re-run apply periodically to refresh the replication state:

```bash
terraform apply
```

Wait until the output shows:
```
next_step = "READY: Run 'terraform apply -var=\"perform_migration=true\"' to start migration"
```

### Step 3: Migrate

Once replication is complete (state = `Protected`), trigger the planned failover:

```bash
terraform apply -var="perform_migration=true"
```

## Key Outputs

| Output | Description |
|--------|-------------|
| `replication_status` | Current replication state, health, and allowed jobs |
| `next_step` | Guidance on what to do next |
| `protected_item_id` | The ID of the replicated VM's protected item |
| `migration_triggered` | Whether migration was triggered |
| `migration_operation_details` | Migration operation response (when triggered) |

## Example terraform.tfvars

Copy `terraform.tfvars.example` and update with your values.
