terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group first
resource "azurerm_resource_group" "rg" {
  name     = "kogoncloudconsulting-storage-rg"
  location = "westus2"
}

# Create a basic virtual network and subnet for private endpoint
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-storage-test"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "endpoint" {
  name                 = "snet-endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies_enabled = true
}

# Create an action group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-storage-test"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "ag-storage"

  email_receiver {
    name          = "sendtodevs"
    email_address = "mark.kogon@markkogon.com"
  }
}

# Call the storage module
module "storage" {
  source              = "../../modules/storage"
  project_name        = "demo"
  environment         = "dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allowed_ips         = ["24.22.103.75"] # Your IP address
  subnet_id           = azurerm_subnet.endpoint.id
  action_group_id     = azurerm_monitor_action_group.main.id
}
