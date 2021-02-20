provider "azurerm" {
  features {}
}

# create a resource group
resource "azurerm_resource_group" "demo" {
  name     = "demo"
  location = var.location
}
