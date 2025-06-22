# Terraform Apply Action

This action runs a standardized Terraform apply operation with all necessary setup. It first checks for changes and only applies if changes are detected.

## Features

- ✅ Azure CLI authentication
- ✅ Conditional AKS kubeconfig setup
- ✅ Terraform cache management
- ✅ Dynamic variable setting from secrets
- ✅ Pre-apply change detection
- ✅ Auto-approve for detected changes
- ✅ Detailed apply output and summary

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

| Output           | Description                                    |
| ---------------- | ---------------------------------------------- |
| `apply-exitcode` | Terraform apply exit code (0=success, 1=error) |

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

## Behavior

1. **Pre-check**: Runs `terraform plan` to detect changes
2. **No changes**: Exits successfully without applying
3. **Changes detected**: Runs `terraform apply -auto-approve`
4. **Error handling**: Fails gracefully with detailed error reporting
