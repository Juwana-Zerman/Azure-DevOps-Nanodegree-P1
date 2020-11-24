# Azure-DevOps-Nanodegree-P1
# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, a Packer template was created and a Terraform template was used to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Fork and/or Clone this repository

2. Make sure you have the following dependencies installed:

### Dependencies
* Create an [Azure Account](https://portal.azure.com)
* Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* Install [Packer](https://www.packer.io/downloads)
* Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. In the terminal run ```az login``` to login to your Azure account. Enter you credentials if needed. In the output one can acquire their subscription id from the id field or use the command ```az account show --query "{ subscription_id }"```. This id will be used in the packer build.
<br>

2. Create a security policy using the following command in the terminal:
    Run ``` az policy definition create --name tagging-policy --mode indexed --rules policy.json ```
<br>

3. Assign policy with the following command in the terminal:
    Run ``` az policy assignment create --policy tagging-policy ```
<br>


4. Create an azure service principal to use terraform with the following command:
    Run ```az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"```
<br>
With this output you will have the client_id and client_secret password to enter into your environment variables for packer. Enter these variables along with your subscription id into the server.json file
<br>

5. Create a packer resource group with this command in the terminal (this is an L for location in the command):
        Run ```az group create -n packerResourceGroup -l eastus```
<br>

6. Run the following command in the terminal to create and deploy your vm machine image to Azure using Packer. Set your client_id, client_secret, and subscription_id as environment variables in the server.json file if you haven't done so already.
    Run ```packer build server.json```
<br>

7. Use terraform to provision resources:
<br>

    * You may customize your vm_count (default is set to 2), admin_username, and admin_password to log into your vms in the ```vars.tf``` file.
    <br>

    * Run ```terraform init```
    <br>

    * Run ```terraform plan -out solution.plan``` to see any changes that are required for your infrastructure and fix those.
    <br>

    * Run ```terraform apply "solution.plan"```
    <br>

    * When you are finished, Run ```terraform destroy``` to destroy the resources to keep charges from accruing.
    <br>

    * You will have to delete the packer resource group manually in the Azure portal or by running the following command: ```az group delete --name packerResourceGroup --yes```
    <br>
    * There may also be a networkwatcher RG that will need deleting manually as well. Use the Azure portal or run ```az group delete --name NetworkWatcherRG --yes```
<br>
##### You have now successfully deployed a scalable IaaS web server in Azure and destroyed it!