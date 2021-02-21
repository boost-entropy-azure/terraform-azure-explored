provider "azurerm" {
  features {}
}

# creating resource group
resource "azurerm_resource_group" "name" {
  name     = "demo"
  location = var.location
}
