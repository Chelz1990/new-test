resource "azurerm_public_ip" "vm_test_ip" {
  name                = "vm-test-public-ip"
  resource_group_name = azurerm_resource_group.azure-project.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_virtual_machine" "vm_test" {
  name                  = "test-vm"
  resource_group_name = azurerm_resource_group.azure-project.name
  location            = var.location
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface_security_group_association" "nsg" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}