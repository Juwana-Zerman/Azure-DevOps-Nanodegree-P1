variable "prefix" {
  description = "The prefix used for all resources in this example"
  default     = "udacity-project1"
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources are created"
  default     = "project1"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "image" {
    description = "The name of the Packer image used"
    default     = "project1PackerImage"
}
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}
variable "admin_username" {
  description = "The username to sign into your vms"
  default     = "adminuser"
}

variable "admin_password" {
  description = "The password to sign into your vms"
  default     = "Passwd#1"
}

variable "application_port" {
  description = "The port that will be exposed to the loadbalancer"
  default     = 80
}