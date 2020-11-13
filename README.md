# Azure-DevOps-Nanodegree-P1
# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
* Create a security policy using the following command:
    * az policy definition create --name tagging-policy --mode indexed --rules policy.json

* Assign policy with the following command:
    * az policy assignment create --policy tagging-policy

* Create a Packer template
    * Add content to the builders section of the template.

* Create a Terraform template:
    