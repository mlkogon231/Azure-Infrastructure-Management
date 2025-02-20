terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storage" {
  name                     = "stdemo${var.environment}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Changed to LRS for demo
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true
  }

  # Simplified network rules
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
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
