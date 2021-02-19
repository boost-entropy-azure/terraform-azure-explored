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

### Availability Zones    
- Availability Zones can protect our applications and data against datacenter failure
- Not all regions support Availability Zones, we'll have to check the region map at [https://azure.microsoft.com/en-us/global-infrastructure/geographies/](https://azure.microsoft.com/en-us/global-infrastructure/geographies/) see whether our region supports Availability Zones
- Each Availability Zone is a **uniqure physical location** within the same region
    - They are made up of one or more datacenters with **independent power, cooling and networking**
- There are 2 categories of services that support Availability Zones:
    - **Zonal services** : we specify in what Availability Zone they run (for example a VM, Managed Disk, ...)
    - **Zone-Redundant** : services that automatically replicate across zones (for example zone redundant storage)
- Be aware that Availability Zone identifiers (1,2,3) are **mapped differently** for each subscription
- Availability Zone 1 can be different in subscription A than in subscription B

### Fault & Update Domains 
- **Fault Domain**: logical group of underlying hardware with **common power source and network switch**, like a rack in on-premises terminology
- **Update Domain**: logical group of underlying hardware that can undergo **maintenance or be rebooted** at the same time
- We generally want to make sue that our Virtual Machines are in a different fault domain and update domain, to ensure high availability for our application when a power source / network switch fails or when an update is performed and the machine is temporary offline
    - This especially when we can't place our VMs cross-zone, for example when region we're in doesn't support multiple Availability Zones


### Scale Sets
- A scale set launches a group of Virtual Machines
- We can manually or automatically **scale up or down** by **adding or removing** VMs
- This is horizontal scalability, we add or remove VMs, the size or type of the VM stays the same
- We typically create an autoscaling group with x amount of instances
- We can then create autoscaling rules or manually change the size when demand is higher
- Scale sets provide **hifh availability and application resiliency**
    - If one of the Vms has a problem, another VM can still handle requests
- All VMs should have the same VM type, base OS and configuration, making it **easy to handle one, ten or hundreds VMs** in a scale set
- We typically put a **Load Balancer** in front of the VMs to load balance the requests over the multiple VMs
- Using scale sets can also save money, by **better resource utilization**
    - We can scale up when demand is high, but also scale down when demand is low
- Virtual Machine Scale Sets are created with **5 fault domains by default in a region without Availability Zones**
    - This ensures that the VMs are spread over the datacenter to increase availabilty 
- If the region supports **Availability Zones**, then the value of fault domains will be **1 in each of the zones**
    - In this case the VM instances will be **spread across multiple zones**, across as many racks on a best effort basis
- Another advantage of Scale Sets is that we can enable **"Automatic OS image upgrades"**
- During the upgrade the **OS disk of the VM will be replaced** with the latest version, and a configured health probe will check whether it was successful
- This can be done one by one or in batch , taking into account a max percentage of images that can be unhealthy
    - The process will also stop if there more than a certain percent **unhealthy VMs post-upgrade**
- Currently offered on the official **UbuntuServer** images, **CentOS** and specific **WindowsServer** versions

### Load Balancers
- Once we have our scale set, we typically put a **Load Balancer** in front of it 
- The Azure Load Balancer supports **inbound and outbound traffic**
    - Inbound: **from internet to the Load Balancer** to our backend VMs
    - Outbound: **from our backend** VMs **to the internet**
- To route the traffic from the Load Balancer to the backends, we setup Load Balancer Rules
    - For example, port 80 (http) to port 8080 (application) on the VM backends
- Azure Load Balancers are available with **2 different SKUs**: Basic & Standard
- Basic is currently available at **no extra charge**
- **Standard incurs a charge**, but supports extra features and scaling (it supports Availability Zones)
- The Standard Load Balancer provides a **zone-redundant frontend** for inbound and outbound traffic
    - Only 1 public IP of type Standard (instead of Basic) need sto be assigned, which will **automatically reroute traffic if a zone failure would occur** (a 2 public IP zone-specific solution is also possible for more granular control)
- Beside Load Balancing we can also do **port-forwarding**, creating an **inbound NAT rule** to forward a port from the Load Balancer to a specific backend
    - Used for example to map unique ports on the Load Balancer to port 22 on the backends
    - Port 50002 On Load Balancer => backend 1:22
    - Port 50003 On Load Balancer => backend 2:22
- This type of Load Balancer **doesn't terminate, respond or interacts with the payload of UDP / TCP packets**, it only forwards it: **it's not a proxy**
    - If we're looking for a Level-7 Load Balancer (which acts like a proxy), then you'll have to implement an **"Application Load Balancer"** - which can also do application layer processing and terminate TLS.