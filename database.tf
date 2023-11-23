# ---------------------------------------------------------------------------

# MySQL Server
resource "azurerm_mysql_server" "wordpress" {
  name                = "project-mysql-server"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  administrator_login          = "adminuser"
  administrator_login_password = "pa$$w0rd868"

  sku_name   = "B_Gen5_1"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                = false
  backup_retention_days            = 7
  geo_redundant_backup_enabled     = false
  public_network_access_enabled    = true
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

# MySQL Database
resource "azurerm_mysql_database" "wordpress" {
  name                = "project-db"
  resource_group_name = azurerm_resource_group.azure-project.name
  server_name         = azurerm_mysql_server.wordpress.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# MySQL Firewall
resource "azurerm_mysql_firewall_rule" "azure" {
  name                = "public-internet"
  resource_group_name = azurerm_resource_group.azure-project.name
  server_name         = azurerm_mysql_server.wordpress.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# ---------------------------------------------------------------------------