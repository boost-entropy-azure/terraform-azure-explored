resource "azurerm_resource_group" "demo1" {
  name     = "resource-group-demo1"
  location = var.location
  tags = {
    env = "resource-group-demo1"
  }

}
