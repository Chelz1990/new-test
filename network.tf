# -----------------------------------------------------------------------

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet #1 for NSG
resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet-1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.azure-project.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet #2 for IGW
resource "azurerm_subnet" "subnet_2" {
  name                 = "subnet-2"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.azure-project.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet #3 for SS
resource "azurerm_subnet" "subnet_3" {
  name                 = "subnet-3"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.azure-project.name
  address_prefixes     = ["10.0.3.0/24"]
}

# -----------------------------------------------------------------------

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group & Subnet #1 Association
resource "azurerm_subnet_network_security_group_association" "nsg-sub" {
  subnet_id                 = azurerm_subnet.subnet_1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -----------------------------------------------------------------------

# Public IP for IGW
resource "azurerm_public_ip" "igw_ip" {
  name                = "test"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  allocation_method = "Dynamic"
}

# Internet Gateway
resource "azurerm_virtual_network_gateway" "igw" {
  name                = "IGW"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.igw_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet_2.id
  }
}

# -----------------------------------------------------------------------

# Public IP for Load Balancer
resource "azurerm_public_ip" "example" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

# Load Balancer (Front-End)
resource "azurerm_lb" "example" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Load Balancer (Back-End)
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "BackEndAddressPool"
}

# Load Balancer Rule
resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = azurerm_lb_backend_address_pool.example.id
}

# -----------------------------------------------------------------------

# Traffic Manager Profile for Load Balancing
resource "azurerm_traffic_manager_profile" "traffic_profile8250" {
  name                   = "traffic-profile8250"
  resource_group_name    = azurerm_resource_group.azure-project.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "traffic-profile8250"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

# End-Point for Traffic Manager
resource "azurerm_traffic_manager_azure_endpoint" "endpoint" {
  name               = "endpoint"
  profile_id         = azurerm_traffic_manager_profile.traffic_profile8250.id
  weight             = 100
  target_resource_id = azurerm_public_ip.public_ip.id
}

# -----------------------------------------------------------------------