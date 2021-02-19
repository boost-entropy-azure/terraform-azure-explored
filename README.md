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

### Virtual Networks

- A **Virtual Network** or **VNet** provides us with a private network in azure.
- A VNet is the first resource we need to have before creating VMs and other services that need *private network connectivity*.
- We need to specify the location(region) where we want to create a VNet and the *address space*
- The address space is the **private IP range** we can then use
    - for example within the 192.168.0.0/16,10.0.0.0/8,172.16.0.0/12 ranges
- Once a VNet is created we can create subnets
    - for example if we create a 10.0.0.0/16 VNet, we could create the following subnets:
        - VM subnet: 10.0.0.0/21 (10.0.0.0 - 10.0.7.255)
        - Database subnet: 10.0.8.0/22(10.0.8.0 - 10.0.11.255)
        - Load Balancer subnet: 10.0.12.0/24(10.0.12.0 - 10.0.12.255)
- We then launch our VM in one specific subnet
- When creating a subnet, azure will reserve **5 IP addresses** for own use:
    - x.x.x.0 : Network address
    - x.x.x.1 : Reserved by Azure for the default gateway
    - x.x.x.2,x.x.x.3 : Reserved by Azure to map the Azure DNS IPs to the VNet space
    - x.x.x.255 : Network broadcast address
- For each subnet we create, azure will create a default route table
- This ensures that IP addresses can be routed to other subnets, virtual networks, a VPN, or to the internet
- We can override the default routes by creating our own custom routes

### Virtual Machines
- We typically need the following to launch a VM:
    - A name
    - The location (typically the same region as our other resources)
    - The resource group
    - A Network Interface
    - the Image(for example Ubuntu)
    - Storage for the OS disk
    - The VM size
    - The OS profile (and a linux or Windows profile)

#### Network Interface
- We can assign a **Network Security Group** to create firewall rules for our instance
- We can assign a private and/or public IP address to a network interface
    - The public IP is an external internet routable IP address
    - The private IP is within our Virtual Network range
    - The allocation can be Dynamic or Static
- For a **private IP addresses**:
    - IP addresses will be released when the network interface is deleted.
    - When using Dynamic allocation, the nest unassigned IP address within the subnets' IP range will be assigned
        - For example within a subnet 192.168.0.0/24:
        - 192.168.0.1 - 192.168.0.3 is reserved
        - 192.168.0.4 will be assigned first ( and if this ine us taken , then 192.168.0.5, and so on)
    - When using Static allocation, we can pick the private IP ourselves 
- For a **public IP addresses**:
    - We have a **Basic SKU**(default) and a **Standard SKU** (which supports Availability Zone scenarios)
    - Basic SKUs can be Dynamic or Static, Standard SKUs can only be Static
    - When assigning a Dynamic public IP, the IP will not be assigned yet when we create the `public_ip` resource. It'll only be assigned when the VM is started
        - The IP is deleted when we stop or delete the resource
    - If we want a static IP (immediately assigned), then we can choose for Static type, and we'll get a static IP from a available public IP pool, until we delete the `public_ip` resource
        - The IP will not be deteted when we stop or delete the resource, enabling us to attach it to another resource

#### The Image:
- We can find images using the **marketplace**
- Typically when we find an publisher, we can list the offers and SKUs that we need in terraform by using:

    ```bash
    az vm image list -p "Microsoft"
    az vm image list -p "Canonical"
    ```

#### OS Storage:
- **OS Storage** is needed to launch a Virtual Machine
- This is provided by an **Azure Managed Disk**
- This is a highly durable and available virtualized disk with three replicas of our data
- *caching*: we can choose what kind of caching we want locally ( on the VM): None, ReadOnly or ReadWrite
- Managed_disk_type:
- LRS stands for "locally redundant storage" which replicates the data three times within one datacenter
- We can currently choose Standard_LRS, StandardSSD_LRS, Premium_LRS or UltraSSD_LRS

#### VM Size:
- General Purpose, Compute optimized, Memory optimized, Storage optimised, GPU, High performanxe Compute
- Within General Purpose we have much more types with each their own characteristics:
    - **B**, Dsv3, Dv3, Dasv4, Dav4, DSv2, Dv2, **Av2**, DC
    - The **B-series** is another interesting type, because it is *burstable* - ideal for workloads that do not need **full performance** of the CPU continuously
    - detailed information of the VM sizes can be found in [azure docs](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)

#### OS Profile (os_profile):
- This is where we can set computer name, login and password

#### OS Profile for Linux (os_profile_linux_config):
- here we can configure an SSH key instead of a password if desired, which is recommended

### Network Security Groups

- Network Security Groups can filter traffic from and to Azure resources
- A Network security group consists of security rules, which have the following parameters:
    - **Name**: unique name of the security group
    - **Priority** : A number between 100 and 4096, with lower numbers proceessed first
    - **Source or destination IP range** (or alternatively a service tag / application security group )
    - **Source & Destination Port Range**
    - **IP Protocal** : TCP / UDP / ICMP / Any
    - **Direction** : incoming / outgoing
    - **Action** : Allow / Deny
- A newly created Network security group has these default **inbound** rules:

| Priority | Source | Source Ports | Destination | Destination Ports | Protocol | Access |
|:--------:|:------:|:------------:|:-----------:|:-----------------:|:--------:|:------:|
| 65000 | VirtualNetwork | 0-65535 | VirtualNetwork | 0-65535 | Any | **Allow**|
|65001 | Azure Loadbalancer | 0-65535 | 0.0.0.0/0 | 0-65535 | Any | **Allow**|
| 65500 | 0.0.0.0/0 | 0-65535 | 0.0.0.0/0 | 0-65535 | Any | **Deny** |

- A newly created Network security group has these default **outbound** rules:

| Priority | Source | Source Ports | Destination | Destination Ports | Protocol | Access |
|:--------:|:------:|:------------:|:-----------:|:-----------------:|:--------:|:------:|
| 65000 | VirtualNetwork | 0-65535 | VirtualNetwork | 0-65535 | Any | **Allow**|
|65001 | 0.0.0.0/0 | 0-65535 | Internet | 0-65535 | Any | **Allow**|
| 65500 | 0.0.0.0/0 | 0-65535 | 0.0.0.0/0 | 0-65535 | Any | **Deny** |
- When creating security groups, instead of IP addresses, we can use **Service Tags** or **Applicaton Security Groups**
- **Service Tags** are predefined by Azure, for example:
    - VirtualNetwork: The VirtualNetwork address space, for example 10.0.0.0/16
    - AzureLoadBalancer: translates to the Virtual IP where Azure health checks originates from
    - Internet: Outside the VirtualNetwork, reachable by the public internet

### Application Security Groups
- Application Security Groups allow us to group Virtual Machines
- Instead of using IP addresses, we can use group names instead, making our Network Security Groups much easier to maintain
- We will need to associate (link) one or more Network Interfaces to an Application Security Group
    - We can associate **multiple network interfaces** that make up 1 application and call the Application Security Group "MyApp"
- Afterwards we'll be able to use that "MyApp" within a network security rule, rather than specifying the single IP addresses

#### Security Groups Troubleshooting
- When creating infrastructure, how do we troubleshoot security Groups ?
- A few general tips:
    - If we're getting "Connection timeout" then it's most likely the security group that is blocking us
        - it can also be that the VM is not responding or we're using the wrong DNS/IP
    - If we're getting "Connection refused", we can reach the VM, and it's the VM that sends us back the port is not open
    - If we're getting a SSH key error, check whether we're using the correct key, and whether we're passing our private key (-i in bash)