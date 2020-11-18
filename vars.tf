variable "prefix" {
  description = "The prefix used for all resources in this example"
  default     = "udacity-project1"
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

variable "address_space" {
  description = "The address space to be used"
  default     = ["10.2.0.0/16"]
}