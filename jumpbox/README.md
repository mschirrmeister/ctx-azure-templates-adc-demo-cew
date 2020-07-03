# Jumpbox

This project includes ARM templates for the Jumpbox servers.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmschirrmeister%2Fctx-azure-templates-adc-demo-cew%2Fmaster%jumpbox%2Fazuredeploy.json)


## Description

This template deploys n+1 machines of the type **Standard_A2**.  
A dedicated storage account is provisioned for the resource group.  
They get provisioned into an existing VNet and Subnet.  

You can define all the above and more in the parameters file.

## Notes

There are 2 ARM templates.

- `azuredeploy.json` and `azuredeploy-<location>.parameters.json` 
- `azuredeploy-inline-script.json` and `azuredeploy-<location>-inline-script.parameters.json` 

Please adjust the variables examples below accordingly.

The template `azuredeploy.json` has a dependcy on a separate storage account from where a script is downloaded and executed via the *Custom Script` extensio for Linux. Details [here](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux)

The template `azuredeploy-inline-script.json` has the script build into the template. This is just for demo purposes and should not used in production. Otherwise if you need to update your script, you have to touch each of you templates.

## Provisioning

#### Variables inline script

    # East US (bash/zsh)
    deploymentName=JumpboxVMs20200624a
    templateFilePath=azuredeploy.json
    parametersFilePath=azuredeploy-east-us.parameters.json
    resourceGroupName=demo-jumpbox-east-us-1
    resourceGroupLocation=eastus
    resourceTags="ServerType=Admin;ServerRole=Jumpbox;Environment=Production"

    # East US (fish)
    set deploymentName JumpboxVMs20200624a
    set templateFilePath azuredeploy.json
    set parametersFilePath azuredeploy-east-us.parameters.json
    set resourceGroupName demo-jumpbox-east-us-1
    set resourceGroupLocation eastus
    set resourceTags "ServerType=Admin;ServerRole=Jumpbox;Environment=Production"

#### Resource group

Before you start provisioning a template, create a resource group for the jumpbox environment.

    az group create --name $resourceGroupName --location $resourceGroupLocation --tags $resourceTags

#### Resources

Validate Template

    az deployment group validate --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath | jq .error.code

Deploy Template

    az deployment group create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath --query '[{fqdn:properties.outputs.fqdn.value}]'

You may receive a error that the ip address that is configured in the **outputs** section does not exists. This is just a timing issue. It queries it to fast and the resource is not fully available yet. If you run the template again, it will return the ip address.

Delete all resources by deleteing the whole group

    az group delete --name $resourceGroupName

#### Login to the instance

Once the instance is provisioned you can login with your ssh key and to the public ip or dns name that you had configured for the public ip. For example.

    ssh -l ctxconfig democewazjb1.eastus.cloudapp.azure.com
