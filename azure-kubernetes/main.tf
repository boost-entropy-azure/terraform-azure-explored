provider "azurerm" {
  features {}
}

provider "azuread" {}


# creating a resource group
resource "azurerm_resource_group" "demo" {
  name     = "kubernetes-demo"
  location = var.location
}
