# GitVersion Action

A GitHub Action that automatically generates semantic version tags for your repository based on commits and provides fallback versioning for development environments.

## Description

This action uses semantic versioning to automatically bump version numbers and create Git tags when code is pushed to the main branch. It provides intelligent version management with automatic patch increments and fallback handling for non-main branches.

## Features

- ✅ Automatic semantic versioning (SemVer)
- ✅ Custom tag prefixes for different components
- ✅ Automatic patch version bumping on main branch
- ✅ Fallback version (0.1.0) for development/feature branches
- ✅ Annotated Git tags with full commit information
- ✅ Integration with GitHub releases

## Inputs

| Input          | Description                                             | Required | Default |
| -------------- | ------------------------------------------------------- | -------- | ------- |
| `prefix`       | Prefix for the tag (e.g., "backend", "frontend", "api") | ✅ Yes    | -       |
| `github-token` | GitHub token for creating tags and releases             | ✅ Yes    | -       |

## Outputs

| Output    | Description                  | Type     | Example            |
| --------- | ---------------------------- | -------- | ------------------ |
| `version` | Full semantic version number | `string` | `1.2.3` or `0.1.0` |

## Usage

### Basic Usage

```yaml
- name: Generate Version Tag
  id: version
  uses: ./.github/actions/version-tag
  with:
    prefix: 'api'
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Use version
  run: |
    echo "Generated version: ${{ steps.version.outputs.version }}"
```

### Multi-Component Versioning

```yaml
jobs:
  version-backend:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Version Backend
        id: backend-version
        uses: ./.github/actions/version-tag
        with:
          prefix: 'backend'
          github-token: ${{ secrets.GITHUB_TOKEN }}

  version-frontend:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Version Frontend
        id: frontend-version
        uses: ./.github/actions/version-tag
        with:
          prefix: 'frontend'
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Complete CI/CD Pipeline

```yaml
name: Build and Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.versioning.outputs.version }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate Version
        id: versioning
        uses: ./.github/actions/version-tag
        with:
          prefix: 'app'
          github-token: ${{ secrets.GITHUB_TOKEN }}

  build:
    needs: version
    runs-on: ubuntu-latest
    steps:
      - name: Build with version
        run: |
          echo "Building version: ${{ needs.version.outputs.version }}"
          # Your build commands here
```

## How it Works

### Main Branch Behavior
1. **Automatic Tagging**: When code is pushed to `main`, automatically creates a new tag
2. **Patch Increment**: By default, increments the patch version (e.g., `1.0.0` → `1.0.1`)
3. **Annotated Tags**: Creates annotated Git tags with full commit information
4. **Tag Format**: Uses format `{prefix}-v{version}` (e.g., `api-v1.2.3`)

### Non-Main Branch Behavior
1. **Fallback Version**: Returns `0.1.0` for development/feature branches
2. **No Tag Creation**: Does not create actual Git tags on non-main branches
3. **Development Support**: Allows builds and deployments to continue with consistent versioning

## Version Examples

### Tag Creation (Main Branch)
```bash
# Previous tag: api-v1.2.2
# New commit pushed to main
# Generated tag: api-v1.2.3
# Output version: 1.2.3
```

### Fallback Version (Feature Branch)
```bash
# Branch: feature/new-feature
# No tag creation
# Output version: 0.1.0
```

## Prefix Usage Examples

Different components can have independent versioning:

```yaml
# Backend API
prefix: 'api'          # Creates tags like: api-v1.2.3
prefix: 'backend'      # Creates tags like: backend-v2.1.0

# Frontend Applications  
prefix: 'web'          # Creates tags like: web-v1.5.2
prefix: 'mobile'       # Creates tags like: mobile-v3.0.1

# Infrastructure
prefix: 'infra'        # Creates tags like: infra-v1.0.5
prefix: 'k8s'          # Creates tags like: k8s-v2.3.1
```

## Advanced Configuration

### Custom Bump Types
The action uses `patch` as default bump, but you can modify the underlying action for:
- `major`: Breaking changes (1.0.0 → 2.0.0)
- `minor`: New features (1.0.0 → 1.1.0)  
- `patch`: Bug fixes (1.0.0 → 1.0.1)

### Integration with Docker
```yaml
- name: Generate Version
  id: version
  uses: ./.github/actions/version-tag
  with:
    prefix: 'app'
    github-token: ${{ secrets.GITHUB_TOKEN }}

- name: Build Docker Image
  run: |
    docker build -t myapp:${{ steps.version.outputs.version }} .
    docker tag myapp:${{ steps.version.outputs.version }} myapp:latest
```

## Dependencies

This action depends on:
- [`mathieudutour/github-tag-action@v6.2`](https://github.com/mathieudutour/github-tag-action) - For automatic tagging

## Requirements

- Repository must be checked out with `fetch-depth: 0` for proper version calculation
- `GITHUB_TOKEN` must have permissions to create tags and releases
- Only creates actual tags when running on the `main` branch

## Best Practices

1. **Use Descriptive Prefixes**: Choose clear prefixes that identify your components
2. **Consistent Naming**: Use the same prefix across all workflows for a component
3. **Fetch Full History**: Always use `fetch-depth: 0` in checkout
4. **Token Permissions**: Ensure GitHub token has appropriate permissions

## Error Handling

- **Missing Token**: Action will fail if `github-token` is not provided
- **Permission Issues**: Fails gracefully if token lacks tag creation permissions
- **Version Calculation**: Falls back to `0.1.0` if version calculation fails

## Troubleshooting

### No Tags Created
- Check if running on `main` branch
- Verify GitHub token permissions
- Ensure repository history is available (`fetch-depth: 0`)

### Version Not Incrementing
- Verify previous tags exist with correct prefix format
- Check commit messages for proper formatting
- Review branch protection rules

## Contributing

This action is part of the m8te.ai infrastructure automation suite. For issues or improvements, please create an issue in the main repository.

## License

This action is licensed under the same terms as the parent repository.
