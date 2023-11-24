# ---------------------------------------------------------------------------

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet #1 for Nothing
resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet_1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.azure-project.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet #2 for Internet Gateway
resource "azurerm_subnet" "subnet_2" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.azure-project.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet #3 for Scale Set
resource "azurerm_subnet" "subnet_3" {
  name                 = "subnet_3"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.azure-project.name
  address_prefixes     = ["10.0.3.0/24"]
}

# ---------------------------------------------------------------------------

# Virtual Network Interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_3.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ---------------------------------------------------------------------------

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  security_rule {
    name                       = "Allow-HTTP"
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
    name                       = "Allow-HTTPS"
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
    name                       = "Allow-SSH"
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

# Network Security Group & Subnet #3 Association
resource "azurerm_subnet_network_security_group_association" "nsg-sub" {
  subnet_id                 = azurerm_subnet.subnet_3.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ---------------------------------------------------------------------------

# Public IP for Internet Gateway
resource "azurerm_public_ip" "igw_ip" {
  name                = "IGW-IP"
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

# ---------------------------------------------------------------------------

# Public IP for Load Balancer
resource "azurerm_public_ip" "example" {
  name                = "Public-IP"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name
  allocation_method   = "Dynamic"
  domain_name_label   = azurerm_resource_group.azure-project.name
}

# Load Balancer (Front-End)
resource "azurerm_lb" "example" {
  name                = "Load-Balancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  frontend_ip_configuration {
    name                 = "Public-IP"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Load Balancer (Back-End) Address Pool
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "BackEndAddressPool"
}

# Load Balancer - Rule - HTTP
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "Public-IP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# Load Balancer - Probe - HTTP
resource "azurerm_lb_probe" "http" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "http-running-probe"
  port                = 80
  protocol            = "Http"
  request_path        = "/index.html"
  number_of_probes    = 3
  interval_in_seconds = 5
}

# ---------------------------------------------------------------------------

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
  target_resource_id = azurerm_public_ip.example.id
}

# ---------------------------------------------------------------------------