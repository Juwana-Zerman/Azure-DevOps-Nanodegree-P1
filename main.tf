terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.35.0"
    }
  }
}

# Configure the Microsoft Azure provider
provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "project1" {
  name     = "${var.prefix}-resources"
  location = "East US"
}

  tags = {
    environment = "project1"
  }

# Create virtual network
resource "azurerm_virtual_network" "project1" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.udacity-project1.location
  resource_group_name = azurerm_resource_group.udacity-project1.name
}

# Create subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.project1.name
  virtual_network_name = azurerm_virtual_network.project1.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create network security group
resource "azurerm_network_security_group" "project1" {
  name                = "${var.prefix}-security-group"
  location            = azurerm_resource_group.project1.location
  resource_group_name = azurerm_resource_group.project1.name

  security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
}
  }

# VM security rules
  resource "azurerm_network_security_rule" "project1vm" {
    name                        = "allow_subnet_vm_inbound"
    priority                    = 200
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "10.0.0.0/16"
    destination_address_prefix  = "10.0.0.0/16"
    resource_group_name         = azurerm_resource_group.project1.name
    network_security_group_name = azurerm_network_security_group.project1.name
  }

  resource "azurerm_network_security_rule" "blockinternetaccess" {
    name                        = "blockinternetaccess"
    priority                    = 300
    direction                   = "Inbound"
    access                      = "Deny"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = azurerm_resource_group.project1.name
    network_security_group_name = azurerm_network_security_group.project1.name
  }

  # Create load balancer
  resource "azurerm_lb" "project1" {
    name                = "${var.prefix}-lb"
    location            = "azurerm_resource_group.project1.location"
    resource_group_name = "azurerm_resource_group.project1.name"

    frontend_ip_configuration {
      name                    = "PublicIpAddress"
      public_ip_address_id    = "azurerm_public_ip.project1.id"
    }
  }

  resource "azurerm_lb_backend_address_pool" "project1" {
    resource_group_name = "azurerm_resource_group.project1.name"
    loadbalancer_id     = "azurerm_lb.project1.id"
  }

  output "backend_address_pool_id" {
    value = "azurerm_lb_backend_address_pool.project1.id"
  }

  resource "azurerm_lb_probe" "project1" {
    resource_group_name = "azurerm_resource_group.project1.name"
    loadbalancer_id     = "azurerm_lb.project1.id"
    name                = "SSH Running Probe"
    port                = 22
  }

  resource "azurerm_lb_rule" "project1" {
    resource_group_name       = "azurerm_resource_group.project1.name"
    loadbalancer_id           = "azurerm_lb.project1.id"
    name                      = "LBRule"
    protocol                  = "TCP"
    frontend_port             = 3389
    backend_port              = 3389
    frontend_ip_configuration = "PublicIpAddress"
  }

  # Create public ip address
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

# Create network interface
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
  tags = {
    environment = "project1"
  }
}

# Connect security group to the network interface
resource "azurerm_network_interface_security_group_association" "project1" {
  count                       = "${var.vm_count}"
  network_interface_id        = "azurerm_network_interface.project1[count.index].id"
  network_security_group_id   = "azurerm_network_security_group.project1.id"
}

# Create and display SSH key
resource "tls_private_key" "project1_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key" {
  value = "tls_private_key.project1_ssh.private_key_pem"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "project1" {
  count                           = "${var.vm_count}"
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.project1.name
  location                        = azurerm_resource_group.project1.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  source_image_id                 = azurerm_image.project1PackerImage.id
  availability_set_id             = azurerm_availability_set.project1_as.id
  network_interface_ids = [
    azurerm_network_interface.project1[count.index].id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    create_option        = "FromImage"
  }
}

# Specify image
data "azurerm_image" "image" {
  name                = "${var.prefix}"
  resource_group_name = "azurerm_resource_group.project1.name"
}

output "image_id" {
  value = data.azurerm_image.search.id
}

# Create availability set
resource "azurerm_availability_set" "project1_as" {
  name                = "project1_as"
  location            = "azurerm_resource_group.project1.location"
  resource_group_name = "azurerm_resource_group.project1.name"
}

# Create managed disk
resource "azurerm_managed_disk" "project1" {
  count                 = "${var.vm_count}"
  name                  = "${var.prefix}-datadisk-${count.index}"
  location              = "azurerm_resource_group.project1.location"
  resource_group_name   = "azurerm_resource_group.project1.name"
  storage_account_type  = "Standard_LRS"
  create_option         = "Empty"
  disk_size_gb          = 5
}

resource "azurerm_virtual_machine_data_disk_attachement" "project1" {
  count               = "${var.vm_count}"
  managed_disk_id     = "azurerm_managed_disk.project1[count.index].id"
  virtual_machine_id  = "azurerm_linux_virtual_machine.project1[count.index].id"
  lun                 = "10"
  caching             = "ReadWrite"
}

