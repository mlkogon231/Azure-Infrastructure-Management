# modules/webapp/main.tf

locals {
  tags = merge(var.tags, {
    Module    = "webapp"
    ManagedBy = "Terraform"
  })
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = format("rg-%s-%s", var.project_name, var.environment)
  location = var.location
  tags     = local.tags
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = format("plan-%s-%s", var.project_name, var.environment)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.tags
}

# Web App
resource "azurerm_linux_web_app" "app" {
  name                = format("app-%s-%s", var.project_name, var.environment)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  tags                = local.tags

  site_config {
    application_stack {
      node_version = "18-lts"
    }
    always_on = true
  }

  app_settings = merge(var.app_settings, {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights.connection_string
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~18"
    "DATABASE_URL"                          = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  })
}

# SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = format("sql-%s-%s", var.project_name, var.environment)
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  tags                         = local.tags

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = var.sql_aad_admin_object_id
  }
}

# SQL Database
resource "azurerm_mssql_database" "db" {
  name         = format("sqldb-%s-%s", var.project_name, var.environment)
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = var.sql_db_max_size_gb
  sku_name     = var.sql_db_sku
  tags         = local.tags
}

# Application Insights
resource "azurerm_application_insights" "insights" {
  name                = format("appi-%s-%s", var.project_name, var.environment)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  tags                = local.tags
}

# SQL Firewall Rules
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "app_service" {
  name             = "AllowAppService"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0" # This should be replaced with actual App Service IP
  end_ip_address   = "0.0.0.0" # This should be replaced with actual App Service IP
}
