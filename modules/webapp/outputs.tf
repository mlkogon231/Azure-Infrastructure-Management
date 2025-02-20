# modules/webapp/outputs.tf

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "web_app_name" {
  description = "The name of the web app"
  value       = azurerm_linux_web_app.app.name
}

output "web_app_url" {
  description = "The default URL of the web app"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "sql_server_name" {
  description = "The name of the SQL server"
  value       = azurerm_mssql_server.sql.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "The name of the SQL database"
  value       = azurerm_mssql_database.db.name
}

output "application_insights_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string for Application Insights"
  value       = azurerm_application_insights.insights.connection_string
  sensitive   = true
}
