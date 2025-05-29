locals {
  formatted_github_private_key = format("-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----", replace(var.gh_runner_app_private_key, " ", ""))

  gh_runner_environment_variables = [
    {
      name        = "RUNNER_SCOPE",
      value       = "repo",
      secret_name = null
    },
    {
      name        = "REPO_URL",
      value       = var.gh_runner_repo_url,
      secret_name = null
    },
    {
      name        = "DISABLE_AUTO_UPDATE",
      value       = "true",
      secret_name = null
    },
    {
      name        = "APP_ID",
      value       = var.gh_runner_app_id,
      secret_name = null
    },
    {
      name        = "APP_PRIVATE_KEY",
      value       = null,
      secret_name = "app-key",
    },
    {
      name        = "LABELS",
      value       = var.gh_runner_labels,
      secret_name = null
    }
  ]

  gh_runner_secrets = [
    {
      name  = "app-key"
      value = local.formatted_github_private_key
    }
  ]
}

resource "azurerm_user_assigned_identity" "gh_runner" {
  location            = var.location
  name                = "gh-aca-runner-identity"
  resource_group_name = azurerm_resource_group.aca.name

  tags = var.tags
}


resource "azurerm_role_assignment" "gh_runner_acr" {
  scope                = data.azurerm_container_registry.hub.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.gh_runner.principal_id
}

resource "azurerm_container_app" "aca" {

  count = var.gh_aca_runner_enable ? 1 : 0

  depends_on = [azurerm_role_assignment.gh_runner_acr]

  name                         = "gh-aca-runner"
  container_app_environment_id = azurerm_container_app_environment.aca.id
  resource_group_name          = azurerm_resource_group.aca.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "containerapp"
      image  = var.gh_runner_image
      cpu    = "1"
      memory = "2Gi"

      dynamic "env" {
        for_each = local.gh_runner_environment_variables
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }

    }
  }

  dynamic "secret" {
    for_each = local.gh_runner_secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gh_runner.id]
  }

  registry {
    server   = data.azurerm_container_registry.hub.login_server
    identity = azurerm_user_assigned_identity.gh_runner.id
  }

  tags = var.tags
}
