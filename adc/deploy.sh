#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 -i <subscriptionId> -g <resourceGroupName> -n <deploymentName> -l <resourceGroupLocation> -t <templateFile> -p <parametersFile> -o <output query>" 1>&2; exit 1; }

declare subscriptionId=""
declare resourceGroupName=""
declare deploymentName=""
declare resourceGroupLocation=""
declare templateFile=""
declare parametersFile=""
declare outputs=""

# Initialize parameters specified from command line
while getopts ":i:g:n:l:t:p:o:" arg; do
	case "${arg}" in
		i)
			subscriptionId=${OPTARG}
			;;
		g)
			resourceGroupName=${OPTARG}
			;;
		n)
			deploymentName=${OPTARG}
			;;
		l)
			resourceGroupLocation=${OPTARG}
			;;
		t)
			templateFile=${OPTARG}
			;;
		p)
			parametersFile=${OPTARG}
			;;
        o)
            outputs=${OPTARG}
            ;;
		esac
done
shift $((OPTIND-1))

# Check if full interactive mode
if [ -z "$subscriptionId" ] && [ -z "$resourceGroupName" ] && [ -z "$deploymentName" ] && [ -z "$resourceGroupLocation" ] && [ -z "$templateFile" ] && [ -z "$parametersFile" ] && [ -z "$outputs" ]; then
    IM=TRUE
else
    IM=FALSE
fi

# Prompt for parameters if some required parameters are missing
if [[ -z "$subscriptionId" ]]; then
	echo "Your subscription ID can be looked up with the CLI using: az account show --out json "
	echo "Enter your subscription ID:"
	read subscriptionId
	[[ "${subscriptionId:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
	echo "This script will look for an existing resource group, otherwise a new one will be created "
	echo "You can create new resource groups with the CLI using: az group create "
	echo "Enter a resource group name"
	read resourceGroupName
	[[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$deploymentName" ]]; then
	echo "Enter a name for this deployment:"
	read deploymentName
fi

if [[ -z "$resourceGroupLocation" ]]; then
	echo "If creating a *new* resource group, you need to set a location "
	echo "You can lookup locations with the CLI using: az account list-locations "

	echo "Enter resource group location:"
	read resourceGroupLocation
fi

if [[ -z "$templateFile" ]]; then
	echo "Template file that should be used "
	echo "Enter name of the templateFile:"
	read templateFile
fi

if [[ -z "$parametersFile" ]]; then
	echo "Parameter file that should be used "
	echo "Enter name of the parameterFile:"
	read parametersFile
fi

# Only ask for output parameter, if none of the following options is define. If none are set we assume that we are in interactive mode
if [ "$IM" == TRUE ]; then
    if [[ -z "$outputs" ]]; then
    	echo "Outputs that should be returned "
    	echo "Enter query for outputs:"
    	read outputs
    fi
fi

#templateFile Path - template file to be used
templateFilePath="${templateFile:-azuredeploy.json}"

if [ ! -f "$templateFilePath" ]; then
	echo "$templateFilePath not found"
	exit 1
fi

#parameter file path
parametersFilePath="${parametersFile:-azuredeploy.parameters.json}"

if [ ! -f "$parametersFilePath" ]; then
	echo "$parametersFilePath not found"
	exit 1
fi

if [ -z "$subscriptionId" ] || [ -z "$resourceGroupName" ] || [ -z "$deploymentName" ]; then
	echo "Either one of subscriptionId, resourceGroupName, deploymentName is empty"
	usage
fi

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
	az login
fi

#set the default subscription id
az account set --subscription $subscriptionId

set +e

#Check for existing RG
az group show --name $resourceGroupName 1> /dev/null

if [ $? != 0 ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
	)
	else
	echo "Using existing resource group..."
fi

#Start deployment
echo "Starting deployment..."
(
    if [ -z "$outputs" ]; then
        set -x
	    az deployment group create --name "$deploymentName" --resource-group "$resourceGroupName" --template-file "$templateFilePath" --parameters "@${parametersFilePath}"
    else
        set -x
        az deployment group create --name "$deploymentName" --resource-group "$resourceGroupName" --template-file "$templateFilePath" --parameters "@${parametersFilePath}" --query "$outputs"
    fi
)

if [ $?  == 0 ];
 then
	echo "Template has been successfully deployed"
fi
