## Importing existing ResourceGroup in Azure to terraform

- Login in to the azure in `az` cli with the `az login` command
- List the resource groups in our azure account with the `az group list` command, which will list all the resource groups in logged in azure account
eg:
```bash
>> az group list

{
  "id": "/subscriptions/c8f32571-55dd-5a59-0000-7e149764bae3/resourceGroups/rg-sample",
  "location": "westus",
  "managedBy": null,
  "name": "rg-sample",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```
- Now that we have the list of resource groups, in `main.tf` file or in a new `resourcegroup.tf` file, create a `azurerm_resource_group` resource block , the `name` field must be same as that of the existing resource group in azure as well as the `location` field
```HCL
# create resource group
resource "azurerm_resource_group" "imprg"{
    name = "rg-sample"
    location = "westus"
}
```
- Let's import the resource group with the `terraform import` command along with the following arguments `terraform import azurerm_resource_group.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<resourcegroupname>`

```bash
>> terraform import azurerm_resource_group.imprg /subscriptions/c8f32571-55dd-5a59-0000-7e149764bae3/resourceGroups/rg-sample

azurerm_resource_group.rg: Importing from ID "/subscriptions/c8f32571-55dd-5a59-0000-7e149764bae3/resourceGroups/rg-sample"..
.
.
azurerm_resource_group.rg: Import prepared!
  Prepared azurerm_resource_group for import
azurerm_resource_group.rg: Refreshing state... [id=/subscriptions/c8f32571-55dd-5a59-0000-7e149764bae3/resourceGroups/rg-sample]

Import successful!
```

- Now, let's confirm that our resource group is indeed in the state file by running `cat terraform.tfstate` to display the contents

> ### Note:
> if needed set the environment variable `ARM_SKIP_PROVIDER_REGISTRATION` to `true`

### setting environment variable in powershell
To create an environment variable that is local to our current PowerShell session, simply use:
```bash
$env:ARM_SKIP_PROVIDER_REGISTRATION = 'true'
```

we can check the value of the environment variable with this code:

```bash
Get-ChildItem Env:ARM_SKIP_PROVIDER_REGISTRATION
```
The variable will vanish when the PowerShell process ends.