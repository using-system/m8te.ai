# Terraform Analyze Action

This action runs Terraform analysis tasks including formatting check, initialization, validation, and security scanning with Checkov.

## Features

- ✅ Terraform formatting check (`terraform fmt`)
- ✅ Terraform initialization
- ✅ Terraform validation
- ✅ Security scanning with Checkov
- ✅ Terraform cache management
- ✅ Standard backend configuration

## Inputs

| Input                   | Description           | Required | Default |
| ----------------------- | --------------------- | -------- | ------- |
| `layer`                 | Terraform layer name  | ✅        | -       |
| `environment`           | Environment name      | ✅        | -       |
| `azure-client-id`       | Azure Client ID       | ✅        | -       |
| `azure-subscription-id` | Azure Subscription ID | ✅        | -       |
| `azure-tenant-id`       | Azure Tenant ID       | ✅        | -       |

## Usage

```yaml
- name: Terraform Analyze
  uses: ./.github/actions/tf-analyze
  with:
    layer: ${{ matrix.layer }}
    environment: ${{ matrix.environment }}
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
```

## What it does

1. **Format Check**: Ensures code follows Terraform formatting standards
2. **Initialize**: Sets up Terraform backend and downloads providers
3. **Validate**: Validates Terraform configuration syntax and logic
4. **Security Scan**: Runs Checkov to identify security issues and compliance violations

## Dependencies

- `hashicorp/setup-terraform@v3`
- `actions/cache@v4`
- `using-system/devops/github/actions/checkov@main`
