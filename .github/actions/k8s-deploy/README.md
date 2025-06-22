# Kubernetes Deploy Action

This action deploys applications to Kubernetes clusters running on Azure Kubernetes Service (AKS).

## Description

This composite action handles the complete Kubernetes deployment workflow:
- Authenticates with Azure using OIDC
- Configures kubectl access to AKS cluster
- Updates the deployment image
- Waits for rollout completion
- Creates deployment tags for tracking

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `environment` | Deployment environment (e.g., dev-app, prd-app) | ✅ | - |
| `app-name` | Application name for the deployment | ✅ | - |
| `image` | Docker image to deploy (with tag and digest) | ✅ | - |
| `namespace` | Kubernetes namespace for deployment | ✅ | - |
| `aks-cluster-name` | AKS cluster name | ❌ | "" |
| `aks-resource-group` | AKS resource group | ❌ | "" |
| `azure-client-id` | Azure Client ID for OIDC authentication | ✅ | - |
| `azure-tenant-id` | Azure Tenant ID for OIDC authentication | ✅ | - |
| `azure-subscription-id` | Azure Subscription ID for OIDC authentication | ✅ | - |
| `github-token` | GitHub token for creating deployment tags | ✅ | - |

## Prerequisites

- Azure Kubernetes Service (AKS) cluster
- Azure Service Principal with appropriate permissions:
  - AKS cluster access (Azure Kubernetes Service Cluster User Role)
  - Resource group reader access
- GitHub repository configured with OIDC trust relationship
- Required secrets configured in GitHub:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID` 
  - `AZURE_SUBSCRIPTION_ID`
  - `GITHUB_TOKEN`
- kubectl and kubelogin available on the runner
- Kubernetes deployment already exists in the target namespace

## Usage

### Basic Example

```yaml
- name: Deploy to Kubernetes
  uses: ./.github/actions/k8s-deploy
  with:
    environment: dev-app
    app-name: my-app
    image: myregistry.azurecr.io/my-app:v1.0.0@sha256:abc123
    namespace: my-namespace
    aks-cluster-name: my-aks-cluster
    aks-resource-group: my-resource-group
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Complete Workflow Example

```yaml
name: Deploy Application
on:
  push:
    branches: [main]

permissions:
  contents: write
  id-token: write

jobs:
  deploy:
    runs-on: self-hosted
    environment: production
    strategy:
      fail-fast: false
      matrix:
        env: [
          { name: "dev-app", infra: "stg-infra"},
          { name: "prd-app", infra: "prd-infra"}
        ]
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy to Kubernetes
        uses: ./.github/actions/k8s-deploy
        with:
          environment: ${{ matrix.env.name }}
          app-name: my-application
          image: ${{ needs.build.outputs.image_name }}
          namespace: "app-${{ matrix.env.name }}"
          aks-cluster-name: "my-aks"
          aks-resource-group: "rg-${{ matrix.env.infra }}-aks"
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## How it Works

1. **Azure Authentication**: Uses Azure OIDC to authenticate with Azure services
2. **Kubeconfig Setup**: Gets AKS credentials and configures kubectl with Azure CLI authentication
3. **Image Update**: Updates the deployment's container image using `kubectl set image`
4. **Rollout Status**: Waits for the deployment rollout to complete (300s timeout)
5. **Deployment Tagging**: Creates/updates a Git tag for deployment tracking

## Deployment Tracking

The action automatically creates Git tags to track deployments:
- **Tag format**: `{environment}-{app-name}`
- **Example**: `dev-app-my-application`, `prd-app-my-application`
- Old deployment tags are removed before creating new ones

## Security

- Uses Azure OIDC for secure, keyless authentication
- No long-lived credentials stored in GitHub secrets
- Follows Azure and Kubernetes security best practices
- Uses service principal with minimal required permissions

## Requirements

### Runner Requirements
- kubectl CLI tool
- kubelogin CLI tool (for Azure AD authentication)
- Azure CLI (installed automatically with azure/login action)

### Kubernetes Requirements
- Deployment must already exist in the target namespace
- Service principal must have appropriate RBAC permissions in the cluster
- Container name in deployment must match the app-name input

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify OIDC trust relationship is configured correctly
   - Check that required secrets are set in GitHub
   - Ensure the service principal has AKS cluster access

2. **Kubeconfig Failed**
   - Verify AKS cluster name and resource group are correct
   - Check that the service principal has reader access to the resource group
   - Ensure the cluster exists and is accessible

3. **Deployment Update Failed**
   - Verify the deployment exists in the specified namespace
   - Check that the container name matches the app-name
   - Ensure the service principal has appropriate RBAC permissions in Kubernetes

4. **Rollout Timeout**
   - Check if the new image is valid and accessible
   - Verify resource limits and requests are appropriate
   - Review pod logs for startup issues
   - Consider increasing the timeout if deployment is slow

### Debug Mode

Enable debug logging by setting the `ACTIONS_STEP_DEBUG` secret to `true` in your repository settings.

### Useful Commands for Debugging

```bash
# Check deployment status
kubectl get deployment {app-name} -n {namespace}

# Check pod status  
kubectl get pods -n {namespace}

# View deployment logs
kubectl logs deployment/{app-name} -n {namespace}

# Check rollout history
kubectl rollout history deployment/{app-name} -n {namespace}
```

## Migration from template-k8s-deploy.yml

If you're migrating from the old `template-k8s-deploy.yml` workflow:

**Before:**
```yaml
uses: ./.github/workflows/template-k8s-deploy.yml
with:
  environment: dev-app
  app-name: my-app
  image: myregistry.azurecr.io/my-app:v1.0.0
  namespace: my-namespace
  private-runner: my-runner
  aks-cluster-name: my-aks
  aks-resource-group: my-rg
secrets: inherit
```

**After:**
```yaml
runs-on: my-runner
environment: dev-app
steps:
  - name: Checkout repository
    uses: actions/checkout@v4
    
  - name: Deploy to Kubernetes
    uses: ./.github/actions/k8s-deploy
    with:
      environment: dev-app
      app-name: my-app
      image: myregistry.azurecr.io/my-app:v1.0.0
      namespace: my-namespace
      aks-cluster-name: my-aks
      aks-resource-group: my-rg
      azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

## License

This action is part of the m8te.ai infrastructure and follows the same license terms.
