# Terraform Apply Action

This action runs a standardized Terraform apply operation with auto-approve. It directly applies infrastructure changes without pre-checking for changes.

## Features

- ✅ Azure CLI authentication
- ✅ Conditional AKS kubeconfig setup
- ✅ Terraform cache management
- ✅ Dynamic variable setting from secrets
- ✅ Direct apply with auto-approve
- ✅ Simple and efficient workflow

## Inputs

| Input                   | Description                        | Required | Default |
| ----------------------- | ---------------------------------- | -------- | ------- |
| `layer`                 | Terraform layer name               | ✅        | -       |
| `environment`           | Environment name                   | ✅        | -       |
| `azure-client-id`       | Azure Client ID                    | ✅        | -       |
| `azure-subscription-id` | Azure Subscription ID              | ✅        | -       |
| `azure-tenant-id`       | Azure Tenant ID                    | ✅        | -       |
| `aks-cluster-name`      | AKS cluster name (optional)        | ❌        | `""`    |
| `aks-resource-group`    | AKS resource group (optional)      | ❌        | `""`    |
| `vars`                  | Comma-separated list of variables  | ✅        | -       |
| `secrets`               | JSON object containing all secrets | ✅        | -       |

## Outputs

This action has no outputs. It either succeeds or fails based on the Terraform apply result.

## Usage

```yaml
- name: Terraform Apply
  uses: ./.github/actions/tf-apply
  with:
    layer: ${{ matrix.layer }}
    environment: ${{ matrix.environment }}
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    aks-cluster-name: ${{ matrix.aks-cluster-name }}
    aks-resource-group: ${{ matrix.aks-resource-group }}
    vars: ${{ join(matrix.vars, ',') }}
    secrets: ${{ toJSON(secrets) }}
```

## Workflow Integration

This action is typically used in conjunction with the `tf-plan` action:

```yaml
jobs:
  plan:
    # ... plan job configuration
    outputs:
      plan-exitcode: ${{ steps.terraform-plan.outputs.plan-exitcode }}
  
  apply:
    needs: plan
    if: needs.plan.outputs.plan-exitcode == 2  # Only apply if changes detected
    steps:
      - name: Terraform Apply
        uses: ./.github/actions/tf-apply
        # ... inputs
```

## Notes

- The action runs `terraform apply -auto-approve` directly
- No pre-validation is performed (this should be done in the plan phase)
- Changes detection should be handled by the workflow logic, not the action
- The action will fail if Terraform apply fails

## Behavior

1. **Pre-check**: Runs `terraform plan` to detect changes
2. **No changes**: Exits successfully without applying
3. **Changes detected**: Runs `terraform apply -auto-approve`
4. **Error handling**: Fails gracefully with detailed error reporting
