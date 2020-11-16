terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.35.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "project1" {
  name     = "${var.prefix}-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "project1" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.udacity-project1.location
  resource_group_name = azurerm_resource_group.udacity-project1.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.project1.name
  virtual_network_name = azurerm_virtual_network.project1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "project1" {
  name                    = "project1-pip"
  location                = azurerm_resource_group.project1.location
  resource_group_name     = azurerm_resource_group.project1.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "project1"
  }
}

resource "azurerm_network_interface" "project1" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.project1.name
  location            = azurerm_resource_group.project1.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.project1.id
  }
}

resource "azurerm_linux_virtual_machine" "project1" {
  name                            = "var.prefix-vm"
  resource_group_name             = azurerm_resource_group.project1.name
  location                        = azurerm_resource_group.project1.location
  size                            = "Standard_D2_v3"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.project1.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}