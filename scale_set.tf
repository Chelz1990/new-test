# ---------------------------------------------------------------------------

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vm_ss" {
  name                = "vm-ss"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name
  sku                 = "Standard_F2"
  instances           = 2
  admin_username      = "adminuser"
  admin_password      = "pa$$w0rd"
  custom_data         = filebase64("wordpress.sh")
  health_probe_id     = azurerm_lb_probe.http.id

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name                                   = "IP-Config"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet_3.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
}

# ---------------------------------------------------------------------------