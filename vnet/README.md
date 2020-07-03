# VNet

This project contains an ARM template that creates a VNet.

### How to run

Define variables

    # East US (bash/zsh)
    deploymentName=VNet20200624a
    templateFilePath=azuredeploy.json
    parametersFilePath=azuredeploy-east-us.parameters.json
    resourceGroupName=demo-vnet-east-us-1
    resourceGroupLocation=eastus
    resourceTags="ServerType=Network;ServerRole=VNet;Environment=Testing"

    # East US (fish)
    set deploymentName VNet20200624a
    set templateFilePath azuredeploy.json
    set parametersFilePath azuredeploy-east-us.parameters.json
    set resourceGroupName demo-vnet-east-us-1
    set resourceGroupLocation eastus
    set resourceTags "ServerType=Network;ServerRole=VNet;Environment=Testing"

Create Resource group

    az group create --name $resourceGroupName --location $resourceGroupLocation --tags $resourceTags

Validate template

    az deployment group validate --template-file $templateFilePath --resource-group $resourceGroupName --parameters $parametersFilePath | jq .error.code

Deploy template

    az deployment group create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath

Show deployment

    az deployment group show --name $deploymentName --resource-group $resourceGroupName

Delete vnet

    az group delete --name $resourceGroupName

