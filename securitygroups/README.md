# Security groups

This project includes ARM templates for ADC security groups.

## Description

This template deploys a security group that is referenced in the ADC templates.

## Provisioning

    # East US (bash/zsh)
    deploymentName=SecurityGroups20200624a
    templateFilePath=azuredeploy.json
    parametersFilePath=azuredeploy-east-us.parameters.json
    resourceGroupName=demo-network-security-groups-east-us-1
    resourceGroupLocation=eastus
    resourceTags="ServerType=Security;ServerRole=Groups;Environment=Testing"

    # East US (fish)
    set deploymentName SecurityGroups20200624a
    set templateFilePath azuredeploy.json
    set parametersFilePath azuredeploy-east-us.parameters.json
    set resourceGroupName demo-network-security-groups-east-us-1
    set resourceGroupLocation eastus
    set resourceTags "ServerType=Security;ServerRole=Groups;Environment=Testing"

#### Resource group

Before you start provisioning a template, create a resource group for the security groups.

    az group create --name $resourceGroupName --location $resourceGroupLocation --tags $resourceTags

#### Resources

Validate Template

    az deployment group validate --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath | jq .error.code

Deploy Template

    az deployment group create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath

Delete all resources by deleteing the whole group

    az group delete --name $resourceGroupName

