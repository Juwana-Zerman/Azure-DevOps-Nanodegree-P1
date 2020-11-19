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
1.  Create a security policy using the following command:
    ``` az policy definition create --name tagging-policy --mode indexed --rules policy.json ```

* Assign policy with the following command:
    ``` az policy assignment create --policy tagging-policy ```

* Create a Packer template
    * Add content to the builders section of the template.

* Create a Terraform template


* In the terminal do az login. In the output one can acquire their subscription id from the id field or use the command ```az account show --query "{ subscription_id }"```.

* Create an azure service principal to use terraform with the following command:
    ```az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"```
With this output you will have the client_id and client_secret password to enter into your environment variables.

* Create a resource group with this command:
        ```az group create -n project1 -1 eastus```

2. Run the following command to create and deploy your vm machine image to Azure using Packer. Set your client_id, client_secret, and subscription_id as environment variables or copy them into a json file and run this command using your json file name. Here vars.json was used.
    ```packer build -var-file vars.json server.json```

3. 