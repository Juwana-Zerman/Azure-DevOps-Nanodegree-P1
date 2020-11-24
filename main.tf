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
  name     = var.resource_group_name
  location = var.location

  tags = {
    "environment" = "project1"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "project1" {
  name                = "project1-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.project1.name

  tags = {
    "environment" = "project1"
  }
}

# Create subnet
resource "azurerm_subnet" "project1" {
  name                 = "project1-subnet"
  resource_group_name  = azurerm_resource_group.project1.name
  virtual_network_name = azurerm_virtual_network.project1.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public ip address
resource "azurerm_public_ip" "project1" {
    # count                   = var.vm_count
    name                    = "project1-pip"
    location                = var.location
    resource_group_name     = azurerm_resource_group.project1.name
    allocation_method       = "Static"
    idle_timeout_in_minutes = 30

  tags = {
    environment = "project1"
  }
}



# Create network security group
resource "azurerm_network_security_group" "project1" {
  name                = "project1-security-group"
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
    name                = "project1-lb"
    location            = var.location
    resource_group_name = azurerm_resource_group.project1.name

    frontend_ip_configuration {
      name                    = "PublicIpAddress"
      public_ip_address_id    = azurerm_public_ip.project1.id
    }

    tags = {
      "environment" = "project1"
    }
  }

  resource "azurerm_lb_backend_address_pool" "project1" {
    name                = "BackendPool"
    resource_group_name = azurerm_resource_group.project1.name
    loadbalancer_id     = azurerm_lb.project1.id
  }
  resource "azurerm_lb_probe" "project1" {
    resource_group_name = azurerm_resource_group.project1.name
    loadbalancer_id     = azurerm_lb.project1.id
    name                = "ssh-running-probe"
    port                = var.application_port
  }

  resource "azurerm_lb_rule" "project1" {
    resource_group_name             = azurerm_resource_group.project1.name
    loadbalancer_id                 = azurerm_lb.project1.id
    name                            = "http"
    protocol                        = "Tcp"
    frontend_port                   = var.application_port
    backend_port                    = var.application_port
    frontend_ip_configuration_name  = "PublicIpAddress"
    backend_address_pool_id         = azurerm_lb_backend_address_pool.project1.id
    probe_id                        = azurerm_lb_probe.project1.id
  }

# Specify image
data "azurerm_resource_group" "image" {
  name = "packerResourceGroup"
}
data "azurerm_image" "image" {
  name                = var.image
  resource_group_name = data.azurerm_resource_group.image.name
}

# Setup virtual machine availability set and scale set
resource "azurerm_availability_set" "project1_as" {
  name                = "project1_as"
  location            = var.location
  resource_group_name = azurerm_resource_group.project1.name
  managed             = true
}
# Create network interface
resource "azurerm_network_interface" "project1" {
  count                           = var.vm_count
  name                            = "project1-nic-${count.index}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.project1.name

  ip_configuration {
    name                          = "project1-ni-config"
    subnet_id                     = azurerm_subnet.project1.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create linux virtual machine
resource "azurerm_linux_virtual_machine" "project1" {
  count                   = var.vm_count
  name                    = "project1-vm-${count.index}"
  resource_group_name     = azurerm_resource_group.project1.name
  location                = var.location
  size                    = "Standard_B1s"
  admin_username          = "adminuser"
  network_interface_ids   = [
    azurerm_network_interface.project1[count.index].id
  ]
  source_image_id         = data.azurerm_image.image.id

  admin_ssh_key {
    username    = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
resource "azurerm_managed_disk" "project1-md" {
  count                   = var.vm_count
  name                    = "project1-md_${count.index}"
  resource_group_name     = azurerm_resource_group.project1.name
  location                = var.location
  storage_account_type    = "Standard_LRS"
  create_option           = "Empty"
  disk_size_gb            = 5
}

resource "azurerm_virtual_machine_data_disk_attachment" "project1" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.project1-md[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.project1[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}