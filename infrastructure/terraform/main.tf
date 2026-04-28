provider "azurerm" {
  features {}
}

provider "azuread" {
  # Configuration for Microsoft Graph orchestration
}

# --- Identity Maestro Foundation (Azure) ---

resource "azurerm_resource_group" "maestro" {
  name     = "rg-${var.project_name}-foundation-${var.environment}"
  location = var.location
}

# --- Maestro Control Plane (Azure Container Apps) ---

resource "azurerm_container_app_environment" "maestro" {
  name                = "cae-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.maestro.location
  resource_group_name = azurerm_resource_group.maestro.name
}

# --- Institutional Maestro Store (Postgres) ---

resource "azurerm_postgresql_flexible_server" "maestro" {
  name                   = "psql-${var.project_name}-metadata-${var.environment}"
  resource_group_name    = azurerm_resource_group.maestro.name
  location               = azurerm_resource_group.maestro.location
  version                = "13"
  administrator_login    = "maestroadmin"
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2ds_v4"
}

# --- Maestro Secrets & Certificates ---

resource "azurerm_key_vault" "maestro" {
  name                        = "kv-maestro-${var.environment}"
  location                    = azurerm_resource_group.maestro.location
  resource_group_name         = azurerm_resource_group.maestro.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

# --- App Registrations for Identity Orchestration ---

resource "azuread_application" "maestro_orchestrator" {
  display_name = "Entra-ID-Maestro-Orchestration-Service"
  owners       = [var.admin_object_id]

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "User.ReadWrite.All"
      type = "Role"
    }

    resource_access {
      id   = "Group.ReadWrite.All"
      type = "Role"
    }

    resource_access {
      id   = "Application.ReadWrite.All"
      type = "Role"
    }

    resource_access {
      id   = "Policy.ReadWrite.ConditionalAccess"
      type = "Role"
    }
  }
}
