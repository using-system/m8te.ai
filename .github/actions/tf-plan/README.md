# Terraform Plan Action

This action runs a standardized Terraform plan operation with all necessary setup including Azure authentication, kubeconfig setup, and variable management.

## Features

- ✅ Azure CLI authentication
- ✅ Conditional AKS kubeconfig setup
- ✅ Terraform cache management
- ✅ Dynamic variable setting from secrets
- ✅ Detailed plan output and summary
- ✅ Standard backend configuration

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

| Output          | Description                                                 |
| --------------- | ----------------------------------------------------------- |
| `plan-exitcode` | Terraform plan exit code (0=no changes, 2=changes, 1=error) |

## Usage

```yaml
- name: Terraform Plan
  uses: ./.github/actions/tf-plan
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

## Exit Codes

- **0**: No changes detected
- **1**: Error occurred
- **2**: Changes detected and ready to apply
