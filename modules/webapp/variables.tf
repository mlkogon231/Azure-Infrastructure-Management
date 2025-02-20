# modules/webapp/variables.tf

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "app_service_sku" {
  description = "The SKU for the App Service Plan"
  type        = string
  default     = "P1v2"
}

variable "app_settings" {
  description = "Additional app settings for the web app"
  type        = map(string)
  default     = {}
}

variable "sql_admin_username" {
  description = "The administrator username for the SQL server"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL server"
  type        = string
  sensitive   = true
}

variable "sql_aad_admin_object_id" {
  description = "The object ID of the Azure AD administrator for SQL Server"
  type        = string
}

variable "sql_db_max_size_gb" {
  description = "The max size of the SQL database in gigabytes"
  type        = number
  default     = 2
}

variable "sql_db_sku" {
  description = "The SKU for the SQL database"
  type        = string
  default     = "Basic"
}
