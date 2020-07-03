# Citrix ADC

This project includes ARM templates for the Citrix ADCs.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmschirrmeister%2Fctx-azure-templates-adc-demo-cew%2Fmaster%2Fadc%2Fazuredeploy.json)

## Description

This template deploy n+1 machines of the type **Standard\_DS3\_v2**.  
A dedicated diagnostic storage account is provisioned for the resource group.  
All resources get provisioned into an existing VNet and Subnets.  

You can define all the above and more in the parameters file.

This template deploys a Citrix ADC with the following

- Uses a managed disk for the OS
- 2 NICs (frontend and fackend)
- custom data for a SNIP/VIP

Please also install the tool [jq](https://stedolan.github.io/jq/). It is used for output parsing for some commands below.

## Template parameter changes

You need to change/set the following parameters in the parameters file.

- adminPassword
- diagnosticsStorageAccountName
- NetScalerVersion
- imageVersion
- pip_name
- pip\_name\_dns

If you deploy into an existing VNET with subnets

- virtualNetworkName
- vnetRg
- subnetName\_Front
- subnetName\_Back

## Provisioning

This provisioning steps are valid for the deployment via CLI. If you provision this template via the Azure portal, then you don't need to follow the next steps and can jump to the **Initial config on VPX** section.

#### Variables

    # East US (bash/zsh)
    deploymentName=CitrixADC20200624a
    templateFilePath=azuredeploy.json
    parametersFilePath=azuredeploy.parameters.json
    resourceGroupName=demo-citrix-adc-east-us-1
    resourceGroupLocation=eastus
    resourceTags="ServerType=LoadBalancer;ServerRole=CitrixADC;Environment=Testing"

    # East US (fish)
    set deploymentName CitrixADC20200624a
    set templateFilePath azuredeploy.json
    set parametersFilePath azuredeploy.parameters.json
    set resourceGroupName demo-citrix-adc-east-us-1
    set resourceGroupLocation eastus
    set resourceTags "ServerType=LoadBalancer;ServerRole=CitrixADC;Environment=Testing"

#### Azure Marketplace Terms

Before you can deploy a Citrix ADC (aka NetScaler) via the azure-cli, you need to accept the **Azure Marketplace Terms**.  
**Note**: You only need to do this ones.

List editions

    az vm image list-skus --location eastus --publisher citrix --offer netscalervpx-121 --query '[].name'
    az vm image list-skus --location eastus --publisher citrix --offer netscalervpx-130 --query '[].name'

First get the version/urn of the image you want to deploy

    az vm image list --all --publisher citrix --offer netscalervpx-121 --sku netscalerbyol --query '[].urn'
    az vm image list --all --publisher citrix --offer netscalervpx-130 --sku netscalerbyol --query '[].urn'

Now feed the urn (for example `(citrix:netscalervpx-121:netscaler10platinum:121.57.18)` to the following command:

    az vm image terms accept --urn "citrix:netscalervpx-121:netscalerbyol:121.57.18"
    az vm image terms accept --urn "citrix:netscalervpx-130:netscalerbyol:130.58.30"

#### Resource group

Before you start provisioning a template, create a resource group for the ADC environment.

    az group create --name $resourceGroupName --location $resourceGroupLocation --tags $resourceTags

#### Resources

Validate Template

    az deployment group validate --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath | jq

Deploy Template

    az deployment group create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parametersFilePath

Retrieve public ip of the Citrix ADC (aka NetScaler)

    # build in query option
    az deployment group show -g $resourceGroupName -n $deploymentName --query '[{fqdn:properties.outputs.fqdn.value, ip:properties.outputs.publicIPs.value.VM1.publicIP}]'

    # piping to "jq"
    az deployment group show -g $resourceGroupName -n $deploymentName | jq '. | {fqdn: .properties.outputs.fqdn.value, ip: .properties.outputs.publicIPs.value.VM1.publicIP}'

Delete all resources by deleteing the whole group

    az group delete --name $resourceGroupName
    az group delete --name $resourceGroupName --verbose --yes --no-wait

Helper Script

    # interactive
    ./deploy.sh

    # non-interactive
    ./deploy.sh -i <subscriptionId> -g demo-citrix-adc--east-us-1 -n CitrixADC20200624a -l eastus -t azuredeploy.json -p azuredeploy-east-us.parameters.json -o '[{fqdn:properties.outputs.fqdn.value, ip:properties.outputs.publicIPs.value.VM1.publicIP}]'

