# Terraform Setup Action

A GitHub Action that converts the `infra/config.yaml` configuration file to a GitHub Actions matrix format with support for dynamic Terraform variable management.

## Description

This action reads the Terraform configuration from `infra/config.yaml` and converts it to a JSON matrix that can be used with GitHub Actions strategy matrix. It supports specifying which secrets should be converted to TF_VAR_* environment variables for each layer.

## Features

- ✅ **Simple configuration**: Single YAML file to configure all layers and environments
- ✅ **Matrix output**: Ready-to-use JSON matrix for GitHub Actions
- ✅ **Runs-on support**: Configurable runners per environment
- ✅ **Dynamic variables**: Specify required secrets/variables per layer
- ✅ **Clean architecture**: No complex directory scanning
- ✅ **Maintainable**: Explicit configuration over convention

## Configuration File Format

The action reads from `infra/config.yaml` with this structure:

```yaml
layers:
  - name: "app-spoke-resources"
    envs:
      - name: "dev-app"
        runs-on: "arc-stg-runners"
        aks-cluster-name: "m8t-aks"
        aks-resource-group: "m8t-stg-we-aks"
      - name: "prd-app"
        runs-on: "arc-stg-runners"
        aks-cluster-name: "m8t-aks"
        aks-resource-group: "m8t-stg-we-aks"
    vars:
      - "azure_subscription_id"
      - "azure_tenant_id"
  - name: "az-hub-network"
    envs:
      - name: "hub-infra"
        runs-on: "ubuntu-24.04"
        aks-cluster-name: ""
        aks-resource-group: ""
    vars:
      - "azure_subscription_id"
      - "azure_tenant_id"
  - name: "k8s-devops"
    envs:
      - name: "stg-infra"
        runs-on: "arc-stg-runners"
        aks-cluster-name: "m8t-aks"
        aks-resource-group: "m8t-stg-we-aks"
    vars:
      - "azure_subscription_id"
      - "azure_tenant_id"
      - "gh_runner_app_id"
      - "gh_runner_app_installation_id" 
      - "gh_runner_app_private_key"
```

### Configuration Properties

- **name**: The layer directory name (without `infra/` prefix)
- **envs**: Array of environments for this layer
  - **name**: Environment name (should match `.tfvars` filename)
  - **runs-on**: GitHub runner type for this environment
  - **aks-cluster-name**: AKS cluster name for kubeconfig setup (empty string if not needed)
  - **aks-resource-group**: AKS resource group for kubeconfig setup (empty string if not needed)
- **vars**: Array of secret names that should be converted to `TF_VAR_*` environment variables

## Inputs

| Input         | Description                         | Required | Default             |
| ------------- | ----------------------------------- | -------- | ------------------- |
| `config-file` | Path to the configuration YAML file | ❌ No     | `infra/config.yaml` |

## Outputs

| Output   | Description                          | Type     |
| -------- | ------------------------------------ | -------- |
| `matrix` | GitHub Actions matrix in JSON format | `string` |

## Output Format

The action generates a matrix like this:

```json
{
  "include": [
    {
      "layer": "app-spoke-resources",
      "environment": "dev-app",
      "runs-on": "arc-stg-runners",
      "aks-cluster-name": "m8t-aks",
      "aks-resource-group": "m8t-stg-we-aks",
      "vars": ["azure_subscription_id", "azure_tenant_id"]
    },
    {
      "layer": "app-spoke-resources", 
      "environment": "prd-app",
      "runs-on": "arc-stg-runners",
      "aks-cluster-name": "m8t-aks",
      "aks-resource-group": "m8t-stg-we-aks",
      "vars": ["azure_subscription_id", "azure_tenant_id"]
    },
    {
      "layer": "az-hub-network",
      "environment": "hub-infra", 
      "runs-on": "ubuntu-24.04",
      "aks-cluster-name": "",
      "aks-resource-group": "",
      "vars": ["azure_subscription_id", "azure_tenant_id"]
    }
  ]
}
```

**Note**: Layer names in the matrix do NOT include the `infra/` prefix. This should be added in the workflow when referencing file paths.

## Usage

### Basic Usage

```yaml
- name: Setup Terraform Matrix
  id: tf-setup
  uses: ./.github/actions/tf-setup

- name: Display matrix
  run: |
    echo "Matrix: ${{ steps.tf-setup.outputs.matrix }}"
```

### With Custom Config File

```yaml
- name: Setup Terraform Matrix
  id: tf-setup
  uses: ./.github/actions/tf-setup
  with:
    config-file: "custom/path/config.yaml"
```

### Use in Strategy Matrix

```yaml
jobs:
  setup:
    outputs:
      matrix: ${{ steps.tf-setup.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
      - id: tf-setup
        uses: ./.github/actions/tf-setup

  terraform:
    needs: setup
    strategy:
      matrix: ${{ fromJson(needs.setup.outputs.matrix) }}
    runs-on: ${{ matrix.runs-on }}
    steps:
      - name: Set Terraform variables from secrets
        run: |
          # Convert matrix.vars array to comma-separated string
          KEYS="${{ join(matrix.vars, ',') }}"
          echo "Setting variables: $KEYS"
          
          for key in $(echo $KEYS | tr "," "\n"); do
            SECRET_KEY=`echo $key | tr '[:lower:]' '[:upper:]'`
            VAL=`jq -r ".${SECRET_KEY}" <<< $SECRETS`
            echo "TF_VAR_${key}=${VAL}" >> $GITHUB_ENV
          done
        env:
          SECRETS: ${{ toJSON(secrets) }}

      - name: Plan Terraform
        run: |
          echo "Layer: ${{ matrix.layer }}"
          echo "Environment: ${{ matrix.environment }}" 
          cd infra/${{ matrix.layer }}
          terraform plan -var-file="vars/${{ matrix.environment }}.tfvars"
```

## Advantages

- ✅ **Centralized config**: All layer/environment combinations in one file
- ✅ **Runner flexibility**: Different runners per environment
- ✅ **Dynamic variables**: Specify required secrets per layer, converted to TF_VAR_*
- ✅ **No magic**: Explicit configuration, no directory scanning
- ✅ **Version controlled**: Configuration changes are tracked
- ✅ **Simple maintenance**: Add/remove environments by editing YAML
- ✅ **Matrix filtering**: Easy to filter by modified layers
- ✅ **Type safety**: Validates configuration structure

## Migration from Directory Scanning

If you're migrating from a directory-scanning approach:

1. **Create `infra/config.yaml`** with all your layers and environments
2. **Add `vars` arrays** specifying which secrets each layer needs
3. **Update workflows** to use this action instead of directory scanning
4. **Remove old actions** like `tf-environment-matrix` and `filter-matrix`
5. **Update working-directory paths** to include `infra/` prefix

## Example: Complete Workflow Integration

```yaml
name: Infrastructure PR Plan

jobs:
  setup:
    runs-on: ubuntu-24.04
    outputs:
      matrix: ${{ steps.filter-matrix.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - id: modified-layers
        uses: ./.github/actions/tf-modified-layers
        with:
          layers-directory: 'infra'

      - id: tf-setup
        uses: ./.github/actions/tf-setup

      - id: filter-matrix
        run: |
          FULL_MATRIX='${{ steps.tf-setup.outputs.matrix }}'
          MODIFIED_LAYERS='${{ steps.modified-layers.outputs.modified_layers }}'
          
          # Filter matrix to only include modified layers
          FILTERED_MATRIX=$(echo "$FULL_MATRIX" | jq --argjson modified "$MODIFIED_LAYERS" '
            .include as $items |
            {"include": ($items | map(select(.layer as $layer | $modified | index($layer))))}
          ' | jq -c '.')
          
          echo "matrix=$FILTERED_MATRIX" >> $GITHUB_OUTPUT

  plan:
    needs: setup
    if: needs.setup.outputs.matrix != '{"include":[]}'
    runs-on: ${{ matrix.runs-on }}
    strategy:
      matrix: ${{ fromJson(needs.setup.outputs.matrix) }}
    steps:
      - uses: actions/checkout@v4

      - name: Set Terraform variables from secrets
        run: |
          KEYS="${{ join(matrix.vars, ',') }}"
          for key in $(echo $KEYS | tr "," "\n"); do
            SECRET_KEY=`echo $key | tr '[:lower:]' '[:upper:]'`
            VAL=`jq -r ".${SECRET_KEY}" <<< $SECRETS`
            echo "TF_VAR_${key}=${VAL}" >> $GITHUB_ENV
          done
        env:
          SECRETS: ${{ toJSON(secrets) }}

      - name: Terraform Plan
        run: terraform plan -var-file="vars/${{ matrix.environment }}.tfvars"
        working-directory: infra/${{ matrix.layer }}
```

## Dependencies

- `yq` - For YAML processing (available in GitHub runners)
- `jq` - For JSON processing (available in GitHub runners)

## License

This action is licensed under the same terms as the parent repository.
