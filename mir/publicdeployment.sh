#!/bin/bash

location='eastus'
subscription=''
resourcegroup=''
workspace=''

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
    echo "No Subscription or resource group or workspace passed, exiting.."
    echo "Usage ./publicdeployment.sh <subscriptionid> <resourcegroup> <workspace>"
    exit 1
else
    subscription=$1
    resourcegroup=$2
    workspace=$3
fi

az account set -s $subscription
if [ $? != 0 ]; then
    exit 1
fi

set -x
storagename=$resourcegroup"str"
keyvaultname=$resourcegroup"kv"
registryname=$resourcegroup"acr"
logwsname=$resourcegroup"logws"
appinsightsname=$resourcegroup"appin"
nsgname=$resourcegroup"nsg"
vnetname=$resourcegroup"vnet"
subnetname=$resourcegroup"subnet"
vmname=$resourcegroup"vm"
pename=$workspace"pe"
epname=$workspace"ep0"
depname=$workspace"dep0"
set +x

az account set --subscription $subscription
az configure -d location=$location subscription=$subscription group=$resourcegroup workspace=$workspace

az group create -n $resourcegroup --tags owner=suriyak@microsoft.com SkipAutoDeleteTill=2022-05-05
rgid=$(az group show -n $resourcegroup --query id -o tsv)

az storage account create -n $storagename
strid=$(az storage account show -n $storagename --query id -o tsv)

az keyvault create -n $keyvaultname
kvid=$(az keyvault show -n $keyvaultname --query id -o tsv)

az acr create -n $registryname --sku premium
acrid=$(az acr show -n $registryname --query id -o tsv)

appinlocation=$location
if [ $appinlocation == 'westcentralus' ]; then
    echo "Using SouthcentralUS for AppInsight resources"
    appinlocation='southcentralus'
fi

az monitor log-analytics workspace create -n $logwsname -l $appinlocation
logwsid=$(az monitor log-analytics workspace show -n $logwsname --query id -o tsv)
az monitor app-insights component create -a $appinsightsname --workspace $logwsid  -l $appinlocation
aiid=$(az monitor app-insights component show -a $appinsightsname --query id -o tsv)

az ml workspace create -n $workspace --set storage_account=$strid key_vault=$kvid container_registry=$acrid application_insights=$aiid 
wsid=$(az resource show --resource-type Microsoft.MachineLearningServices/workspaces -n $workspace --query id -o tsv)

az ml model create --name $workspace-model1 -v 1 -p .

docker pull suriyakalivardhan/simpleinferencer:v1
docker tag suriyakalivardhan/simpleinferencer:v1 $registryname.azurecr.io/suriyakalivardhan/simpleinferencer:v1
az acr login -n $registryname
docker push $registryname.azurecr.io/suriyakalivardhan/simpleinferencer:v1

az ml online-endpoint create -n $epname --auth-mode=key
az ml online-deployment create -e $epname -n $depname -f publicdep.yml --all-traffic
token=$(az ml online-endpoint get-credentials -n $epname --query primaryKey -o tsv)

curl -X POST https://$epname.$location.inference.ml.azure.com/inference -H "Authorization: Bearer $token" -d '{"Id":"1234", "Type": "Infer", "Input":"InferencingRequest"}'