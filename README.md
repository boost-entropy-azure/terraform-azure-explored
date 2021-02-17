# Exploring Azure with Terraform

[Terraform](https://www.terraform.io/) is an open-source infrastructure as code software tool, with which
aws infrastructure can be created and managed.

### Azure Concepts and Terminology

#### Resource Manager

- The Resource Manager is a **deployment and managament service** in Azure.
- It's the management layer to **create, update and delete** resources in our Azure subscription.
- The terraform AzureRM plugin uses the Azure SDK to connect to the Resource Manager.
  - The resource manager provides **authentication and authorization**

##### Scope

- **Management Groups** --> Groups to manage our subscriptions
- **Subscriptions** --> Trials, Pay as you go, or Enterprise Agreements
- **Resource Groups** --> a logical Container that holds our resources
    - Resource groups are part of the **Resource Manager**
    - A resource can only exixt within a single resource group
        - A resource from on Resource Group can still use a resource from another resource group
        if the permissions allow it
        - For example, we can use a VNet created in one Resource Group, within another Resource Group
    - Even though we assign a Resource Group to a single Region, this is only where the **metadata** is saved
        - we can still create resources in other regions
    - We can also **move a resource** from one resource group to the other
    - **Role Based Access Control (RBAC)** can be applied on the resource group level, allowing us to provide acccess to users on a resource group level.
    - **Tagging** resources can help for billing purposes, but also for automated processes, or audits
    - Resource Groups will also allow us to effectively manage our costs
- **Resources** --> VNets, VMs, Storage,... etc,.

> ### Note:
>
> **Resources --> Resource Groups --> Subscriptions --> Management Groups** . This is the order of scope.
