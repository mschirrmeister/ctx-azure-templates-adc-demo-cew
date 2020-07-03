# Citrix ADC

This project includes ARM templates for the Citrix ADCs.

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

### Deploy everything from this repo

You need to change at least the following parameters in the **ADC** parameters file.

- adminPassword
- diagnosticsStorageAccountName
- NetScalerVersion
- imageVersion
- pip\_name\_dns

You need to change at least the following parameters in the **Jumpbox** parameters file.

- sshkeyData
- pip\_name\_dns

### Deploy into an existing environment

If you deploy into an existing VNET with subnets, you need to change the following parameters.

- virtualNetworkName (ADC/Jumpbox)
- vnetRg (ADC/Jumpbox)
- subnetName\_Front (ADC)
- subnetName\_Back (ADC)
- subnetName (Jumpbox)
- nsgRg (ADC)
- nsg_name (ADC)

## Provisioning

If you have an existing VNET, you only need to deploy the ADC template. Go into the ADC folder and follow the instructions.

If you want to deploy everything, you have 2 options. Either you deploy each component separately (you need to follow an order) or you deploy everything in one go (template with dependencies).

These provisioning steps are valid for the deployment via **Azure CLI**. If you provision this template via the Azure portal, then you don't need to follow the next steps and can jump to the **Initial config on VPX** section.

#### Azure Marketplace Terms

Before you can deploy a Citrix ADC (aka NetScaler) via the azure-cli, you need to accept the **Azure Marketplace Terms**.  
**Note**: You only need to do this ones.

List editions

    az vm image list-skus --location eastus --publisher citrix --offer netscalervpx-121 --query '[].name'
    az vm image list-skus --location eastus --publisher citrix --offer netscalervpx-130 --query '[].name'

First get the version/urn of the image you want to deploy

    az vm image list --all --publisher citrix --offer netscalervpx-121 --sku netscalerbyol --query '[].urn'
    az vm image list --all --publisher citrix --offer netscalervpx-130 --sku netscalerbyol --query '[].urn'

Now feed the urn (for example `(citrix:netscalervpx-121:netscaler10platinum:121.49.24)` to the following command:

    az vm image terms accept --urn "citrix:netscalervpx-121:netscalerbyol:121.57.18"
    az vm image terms accept --urn "citrix:netscalervpx-130:netscalerbyol:130.58.30"

#### Separately

Deployment order

1. vnet
2. subnets
3. jumpbox
4. security groups
5. ADC

Pleae go into the folders, read the instructions and deploy each template.

#### All in one go

After you have modified all the **parameters** and **variables** as mentioned above, you can run the following commands to deploy the ARM templates. This will provision the **vnet, subnet, jumpbox, security group**.

    # Create resource groups
    az deployment sub create --name resourceGroups20200702a --location eastus --template-uri https://raw.githubusercontent.com/mschirrmeister/ctx-azure-templates-adc-demo-cew/master/azuredeploy-rg.json --parameters https://raw.githubusercontent.com/mschirrmeister/ctx-azure-templates-adc-demo-cew/master/azuredeploy-east-us.parameters.json
    
    # Deploy VNET, Jumpbox, security groups and ADC
    az deployment sub create --name resources20200702a --location eastus --template-uri https://raw.githubusercontent.com/mschirrmeister/ctx-azure-templates-adc-demo-cew/master/azuredeploy.json --parameters https://raw.githubusercontent.com/mschirrmeister/ctx-azure-templates-adc-demo-cew/master/azuredeploy-east-us.parameters.json --query '[{ADCFqdn:properties.outputs.adcFqdn.value, ADCIp:properties.outputs.adcPublicIPs.value, jumpboxFqdn:properties.outputs.jumpboxFqdn.value}]'
    
    # Show names
    az deployment sub show --name resources20200702a --query '[{ADCFqdn:properties.outputs.adcFqdn.value, ADCIp:properties.outputs.adcPublicIPs.value, jumpboxFqdn:properties.outputs.jumpboxFqdn.value}]' --output table

## Initial config on VPX

All below is a pure example. The ip addesses can be different for each instance. You want an automated process that would lookup ip addresses to use them later in the config.

After the VPX is provisioned we do the base config. The ip addressing can be different, if you have another range in your VNET.

    add ns ip 10.200.35.6 255.255.255.0 -type snip -vServer DISABLED

    add network route 0.0.0.0 0.0.0.0 10.200.34.1
    rm network route 0.0.0.0 0.0.0.0 10.200.35.1
    disable ns mode mbf

    add server web1 3.220.112.94
    add service web1_80 web1 HTTP 80 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 180 -svrTimeout 360 -CKA NO -TCPB NO -CMP NO
    add lb vServer test_1_80 HTTP 10.200.34.5 80
    bind lb vServer test_1_80 web1_80

    add lb monitor dns_azure_1 DNS -query www.google.com -queryType Address -LRTM DISABLED
    bind service azurelbdnsservice0 -monitorName dns_azure_1
    unbind service azurelbdnsservice0 -monitorName dns

Lets check if our web server is reachable

    http democewazeauscitrixadc1.eastus.cloudapp.azure.com

You should see content from the `httpbin.org` website.

## Delete

Delete all resources.

    az group delete --name demo-jumpbox-east-us-1 --verbose --yes --no-wait
    az group delete --name demo-citrix-adc-east-us-1 --verbose --yes --no-wait

Run these 2 after the above is completed.

    az group delete --name demo-network-security-groups-east-us-1 --verbose --yes --no-wait
    az group delete --name demo-vnet-east-us-1 --verbose --yes --no-wait

