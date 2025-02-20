# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storage" {
  name                     = "st${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    container_delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_ips
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "share" {
  name                 = "share"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

# Private Endpoint for secure access
resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pe-storage-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-storage-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# Storage sync service for file sync
resource "azurerm_storage_sync" "sync" {
  name                = "ss-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_storage_sync_group" "sync_group" {
  name            = "ssg-${var.project_name}-${var.environment}"
  storage_sync_id = azurerm_storage_sync.sync.id
}

# Monitor storage metrics
resource "azurerm_monitor_metric_alert" "storage_latency" {
  name                = "alert-storage-latency-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_storage_account.storage.id]
  description         = "Alert when storage latency exceeds threshold"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "SuccessServerLatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 100
  }

  action {
    action_group_id = var.action_group_id
  }
}
