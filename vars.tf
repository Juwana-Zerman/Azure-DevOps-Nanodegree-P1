variable "prefix" {
  description = "The prefix used for all resources in this example"
  default     = "udacity-project1"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "resource_group_name" {
    description = "The name of the resource group where the resources will be created"
    default     = "test"
}

variable "packer_image_name" {
    description = "The name of the Packer image used"
    default     = "project1PackerImage"
}

variable "packer_resource_group" {
    description = "Resource group used for the Packer image"
    default     = "test"
}

