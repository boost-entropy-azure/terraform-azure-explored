provider "azurerm" {
  features {}
}

# creating a resource group
resource "azurerm_resource_group" "name" {
  name     = "demo"
  location = var.location
}
