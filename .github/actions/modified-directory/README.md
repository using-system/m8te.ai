# Calculate Modified Directories

A GitHub Action that automatically detects which directories have been modified in a Pull Request.

## Description

This action analyzes changed files in a Pull Request and identifies which directories contain modifications. It's particularly useful for CI/CD pipelines that need to process changes only in the modified directories, rather than running operations on all directories. Originally designed for Terraform layers, it now supports any directory structure.

## Features

- ✅ Detects modified directories automatically
- ✅ Returns results as a JSON array for easy processing
- ✅ Handles empty results gracefully
- ✅ Configurable directory depth calculation
- ✅ Works with any directory structure (Terraform, components, etc.)
- ✅ Supports multiple use cases (infra layers, application components, etc.)

## Inputs

| Input            | Description                                      | Required | Default |
| ---------------- | ------------------------------------------------ | -------- | ------- |
| `base-directory` | Base working directory to scan for modifications | ✅ Yes    | -       |

## Outputs

| Output                 | Description                        | Type     |
| ---------------------- | ---------------------------------- | -------- |
| `modified_directories` | JSON array of modified directories | `string` |

## Usage

### Basic Usage - Terraform Layers

```yaml
- name: Calculate Modified Directories
  id: modified-directories
  uses: ./.github/actions/modified-directory
  with:
    base-directory: 'infra'

- name: Display modified directories
  run: |
    echo "Modified directories: ${{ steps.modified-directories.outputs.modified_directories }}"
```

### Basic Usage - Application Components

```yaml
- name: Calculate Modified Components
  id: modified-components
  uses: ./.github/actions/modified-directory
  with:
    base-directory: 'src/components'

- name: Display modified components
  run: |
    echo "Modified components: ${{ steps.modified-components.outputs.modified_directories }}"
```

### Complete CI/CD Example - Terraform

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
      modified_directories: ${{ steps.modified-directories.outputs.modified_directories }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Calculate Modified Directories
        id: modified-directories
        uses: ./.github/actions/modified-directory
        with:
          base-directory: 'infra'

  terraform-plan:
    needs: detect-changes
    if: needs.detect-changes.outputs.modified_directories != '[]'
    strategy:
      matrix:
        layer: ${{ fromJson(needs.detect-changes.outputs.modified_directories) }}
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

### Complete CI/CD Example - Components

```yaml
name: Components CI/CD

on:
  pull_request:
    paths:
      - 'src/components/**'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      modified_directories: ${{ steps.modified-directories.outputs.modified_directories }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Calculate Modified Components
        id: modified-directories
        uses: ./.github/actions/modified-directory
        with:
          base-directory: 'src/components'

  build-components:
    needs: detect-changes
    if: needs.detect-changes.outputs.modified_directories != '[]'
    strategy:
      matrix:
        component: ${{ fromJson(needs.detect-changes.outputs.modified_directories) }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build Component
        run: |
          cd ${{ matrix.component }}
          docker build -t my-component:latest .
```

## How it Works

1. **Calculate Directory Depth**: Automatically calculates the depth of the base directory for optimal file detection
2. **Detect Changed Files**: Uses `tj-actions/changed-files` to identify modified files and directories
3. **Process Results**: Filters the results to return only the relevant directories within the specified base directory
4. **Handle Empty Results**: Gracefully handles cases where no directories are modified

## Example Output

### When directories are modified:
```json
["infra/app-spoke-resources", "infra/k8s-core-resources"]
```

### For components:
```json
["src/components/accountms", "src/components/gateway"]
```

### When no directories are modified:
```json
[]
```

## Directory Structure Support

This action works with any directory structure, such as:

### Terraform Infrastructure
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

### Application Components
```
src/components/
├── accountms/
│   ├── Dockerfile
│   ├── package.json
│   └── ...
├── gateway/
│   ├── Dockerfile
│   ├── package.json
│   └── ...
└── landingapp/
    ├── Dockerfile
    ├── package.json
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

This action is part of the m8te.ai infrastructure and components automation suite. For issues or improvements, please create an issue in the main repository.

## Use Cases

- **Terraform Infrastructure**: Detect modified infrastructure layers for selective deployment
- **Application Components**: Identify changed microservices or components for targeted builds
- **Documentation**: Process only modified documentation sections
- **Any directory-based structure**: Adapt to your specific project organization

## License

This action is licensed under the same terms as the parent repository.
