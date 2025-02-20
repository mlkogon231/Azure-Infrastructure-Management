# modules/monitoring/main.tf

resource "azurerm_monitor_action_group" "critical" {
  name                = "ag-critical-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "critical"

  email_receiver {
    name                    = "oncall-team"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "webapp_response" {
  name                = "alert-webapp-response-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.webapp_id]
  description         = "Alert when web app response time exceeds threshold"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}

resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "alert-sql-cpu-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.sql_server_id]
  description         = "Alert when SQL CPU exceeds threshold"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Diagnostic Settings for Web App
resource "azurerm_monitor_diagnostic_setting" "webapp_diag" {
  name                       = "diag-webapp-${var.environment}"
  target_resource_id         = var.webapp_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  log {
    category = "AppServiceHTTPLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

# Azure Monitor Dashboard
resource "azurerm_dashboard" "monitoring" {
  name                 = "dash-${var.project_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  location             = var.location
  dashboard_properties = <<DASH
{
    "lenses": {
        "0": {
            "order": 0,
            "parts": {
                "0": {
                    "position": {
                        "x": 0,
                        "y": 0,
                        "rowSpan": 4,
                        "colSpan": 6
                    },
                    "metadata": {
                        "inputs": [],
                        "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
                        "settings": {
                            "content": {
                                "Query": "AppServiceHTTPLogs\n| where TimeGenerated > ago(24h)\n| summarize count() by bin(TimeGenerated, 1h), ScStatus\n| render timechart",
                                "Id": "${azurerm_log_analytics_workspace.workspace.id}"
                            }
                        }
                    }
                }
            }
        }
    }
}
DASH
}
