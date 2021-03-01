resource "azurerm_resource_group" "name" {
  name     = "application-gateway-demo"
  location = var.location
}
