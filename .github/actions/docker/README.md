# Docker Build and Push Action

This action builds and pushes Docker images to Azure Container Registry (ACR).

## Description

This composite action handles the complete Docker build and push workflow:
- Sets up QEMU and Docker Buildx for multi-platform builds
- Authenticates with Azure using OIDC
- Logs into Azure Container Registry
- Builds and pushes the Docker image
- Returns the full image name with digest

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `dockerfile` | Path to Dockerfile | ✅ | - |
| `working-directory` | Working directory for Docker build | ✅ | - |
| `image_name` | Docker image name (registry/repository) | ✅ | - |
| `version` | Image version/tag | ✅ | - |
| `azure-client-id` | Azure Client ID for OIDC authentication | ✅ | - |
| `azure-tenant-id` | Azure Tenant ID for OIDC authentication | ✅ | - |
| `azure-subscription-id` | Azure Subscription ID for OIDC authentication | ✅ | - |

## Outputs

| Output | Description |
|--------|-------------|
| `image_name` | Full Docker image name with tag and digest |

## Prerequisites

- Azure Container Registry configured
- Azure Service Principal with appropriate permissions
- GitHub repository configured with OIDC trust relationship
- Required secrets configured in GitHub:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`

## Usage

### Basic Example

```yaml
- name: Build and push Docker image
  uses: ./.github/actions/docker
  with:
    dockerfile: src/app/Dockerfile
    working-directory: src/app
    image_name: myregistry.azurecr.io/myapp
    version: v1.0.0
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Complete Workflow Example

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write

jobs:
  build:
    runs-on: ubuntu-24.04
    environment: build
    outputs:
      image_name: ${{ steps.docker-build.outputs.image_name }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build and push Docker image
        id: docker-build
        uses: ./.github/actions/docker
        with:
          dockerfile: ./Dockerfile
          working-directory: .
          image_name: myregistry.azurecr.io/myapp
          version: ${{ github.sha }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

  deploy:
    needs: build
    runs-on: ubuntu-24.04
    steps:
      - name: Deploy image
        run: |
          echo "Deploying image: ${{ needs.build.outputs.image_name }}"
```

## How it Works

1. **Setup**: Configures QEMU and Docker Buildx for enhanced build capabilities
2. **Authentication**: Uses Azure OIDC to authenticate with Azure services
3. **Registry Login**: Automatically extracts registry name from image_name and logs in
4. **Build & Push**: Builds the Docker image and pushes it to ACR
5. **Output**: Returns the complete image reference including digest

## Registry Name Detection

The action automatically detects the Azure Container Registry name from the `image_name` input:
- Input: `myregistry.azurecr.io/myapp`
- Detected registry: `myregistry`
- Login command: `az acr login --name myregistry`

## Security

- Uses Azure OIDC for secure, keyless authentication
- No long-lived credentials stored in GitHub secrets
- Follows Azure security best practices
- Registry authentication is scoped to the specific registry

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify OIDC trust relationship is configured correctly
   - Check that required secrets are set in GitHub
   - Ensure the service principal has ACR push permissions

2. **Registry Login Failed**
   - Verify the image_name format includes the full registry URL
   - Check that the registry exists and is accessible
   - Ensure the service principal has access to the registry

3. **Build Failed**
   - Check that the dockerfile path is correct relative to working-directory
   - Verify all required files are present in the build context
   - Review build logs for specific error messages

### Debug Mode

Enable debug logging by setting the `ACTIONS_STEP_DEBUG` secret to `true` in your repository settings.

## Migration from template-docker.yml

If you're migrating from the old `template-docker.yml` workflow:

**Before:**
```yaml
uses: ./.github/workflows/template-docker.yml
with:
  dockerfile: src/app/Dockerfile
  working-directory: src/app
  image_name: myregistry.azurecr.io/myapp
  version: v1.0.0
secrets: inherit
```

**After:**
```yaml
uses: ./.github/actions/docker
with:
  dockerfile: src/app/Dockerfile
  working-directory: src/app
  image_name: myregistry.azurecr.io/myapp
  version: v1.0.0
  azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
  azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
  azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## License

This action is part of the m8te.ai infrastructure and follows the same license terms.
