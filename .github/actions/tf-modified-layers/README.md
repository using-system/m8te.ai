# Calculate Modified Terraform Layers

A GitHub Action that automatically detects which Terraform layers have been modified in a Pull Request.

## Description

This action analyzes changed files in a Pull Request and identifies which Terraform layers (directories) contain modifications. It's particularly useful for CI/CD pipelines that need to apply Terraform changes only to the modified layers, rather than running all layers.

## Features

- ✅ Detects modified Terraform layers automatically
- ✅ Returns results as a JSON array for easy processing
- ✅ Handles empty results gracefully
- ✅ Configurable directory depth calculation
- ✅ Works with any directory structure

## Inputs

| Input              | Description                                 | Required | Default |
| ------------------ | ------------------------------------------- | -------- | ------- |
| `layers-directory` | Base working directory for Terraform layers | ✅ Yes    | -       |

## Outputs

| Output            | Description                             | Type     |
| ----------------- | --------------------------------------- | -------- |
| `modified_layers` | JSON array of modified Terraform layers | `string` |

## Usage

### Basic Usage

```yaml
- name: Calculate Modified Terraform Layers
  id: modified-layers
  uses: ./.github/actions/tf-modified-layers
  with:
    layers-directory: 'infra'

- name: Display modified layers
  run: |
    echo "Modified layers: ${{ steps.modified-layers.outputs.modified_layers }}"
```

### Complete CI/CD Example

```yaml
name: Terraform CI/CD

on:
  pull_request:
    paths:
      - 'infra/**'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      modified_layers: ${{ steps.modified-layers.outputs.modified_layers }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Calculate Modified Terraform Layers
        id: modified-layers
        uses: ./.github/actions/tf-modified-layers
        with:
          layers-directory: 'infra'

  terraform-plan:
    needs: detect-changes
    if: needs.detect-changes.outputs.modified_layers != '[]'
    strategy:
      matrix:
        layer: ${{ fromJson(needs.detect-changes.outputs.modified_layers) }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Plan
        run: |
          cd ${{ matrix.layer }}
          terraform init
          terraform plan
```

## How it Works

1. **Calculate Directory Depth**: Automatically calculates the depth of the layers directory for optimal file detection
2. **Detect Changed Files**: Uses `tj-actions/changed-files` to identify modified files and directories
3. **Process Results**: Filters the results to return only the relevant Terraform layers
4. **Handle Empty Results**: Gracefully handles cases where no layers are modified

## Example Output

### When layers are modified:
```json
["infra/app-spoke-resources", "infra/k8s-core-resources"]
```

### When no layers are modified:
```json
[]
```

## Directory Structure Support

This action works with any Terraform directory structure, such as:

```
infra/
├── app-spoke-resources/
│   ├── main.tf
│   ├── variables.tf
│   └── ...
├── k8s-core-resources/
│   ├── main.tf
│   ├── variables.tf
│   └── ...
└── az-hub-network/
    ├── main.tf
    ├── variables.tf
    └── ...
```

## Dependencies

This action depends on:
- [`tj-actions/changed-files@v44`](https://github.com/tj-actions/changed-files) - For detecting changed files

## Requirements

- The repository must be checked out with `fetch-depth: 0` for proper diff calculation
- The action must be run in the context of a Pull Request for change detection

## Error Handling

- Returns an empty array `[]` when no changes are detected
- Handles missing or invalid input gracefully
- Provides clear logging output for debugging

## Contributing

This action is part of the m8te.ai infrastructure automation suite. For issues or improvements, please create an issue in the main repository.

## License

This action is licensed under the same terms as the parent repository.
