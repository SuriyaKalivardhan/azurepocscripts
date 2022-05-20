#!/bin/bash

location='eastus'
subscription=''
resourcegroup=''
workspace=''

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
    echo "No Subscription or resource group or workspace passed, exiting.."
    echo "Usage ./privatedeployment.sh <subscriptionid> <resourcegroup> <workspace>"
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

az group create -n $resourcegroup --tags owner=suriyak@microsoft.com SkipAutoDeleteTill=2022-06-05
rgid=$(az group show -n $resourcegroup --query id -o tsv)

az storage account create -n $storagename
strid=$(az storage account show -n $storagename --query id -o tsv)

az keyvault create -n $keyvaultname
kvid=$(az keyvault show -n $keyvaultname --query id -o tsv)

az acr create -n $registryname --sku premium
acrid=$(az acr show -n $registryname --query id -o tsv)

appinlocation=$location
if [ $appinlocation == 'eastus2euap' ]; then
    echo "Using SouthcentralUS for AppInsight resources"
    appinlocation='eastus'
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

#az storage account update -n $storagename --public-network-access Disabled --bypass AzureServices --default-action Deny
#az keyvault update -n $keyvaultname --public-network-access Disabled --bypass AzureServices --default-action Deny
#az acr update -n $registryname --public-network-enabled false --allow-trusted-services --default-action Deny
#az ml workspace update -n $workspace --public-network-access Disabled

az network nsg create -n $nsgname
az network nsg rule create --nsg-name $nsgname -n AllowCorp --priority 4096  --access Allow --protocol Tcp --source-address-prefixes CorpNetPublic --destination-address-prefixes '*' --destination-port-ranges 22 --direction Inbound
nsgid=$(az network nsg show -n $nsgname --query id -o tsv)

az network vnet create -n $vnetname --address-prefix 10.0.0.0/16 --subnet-name $subnetname --subnet-prefix 10.0.0.0/24 --nsg $nsgid
az network vnet subnet update --vnet-name $vnetname -n $subnetname --disable-private-endpoint-network-policies true
subnetid=$(az network vnet subnet show --vnet-name $vnetname -n $subnetname --query id -o tsv)

az network private-endpoint create -n $pename --vnet-name $vnetname --subnet $subnetname --private-connection-resource-id $wsid --connection-name $pename --group-id amlworkspace
az network private-dns zone create --name privatelink.api.azureml.ms
az network private-dns link vnet create --zone-name privatelink.api.azureml.ms --name privatevnetlink --virtual-network $vnetname --registration-enabled false
az network private-endpoint dns-zone-group create --endpoint-name $pename  --name myzonegroup --private-dns-zone privatelink.api.azureml.ms --zone-name privatelink.api.azureml.ms

az vm create -n $vmname --image UbuntuLTS --admin-username suriyak --ssh-key-value ~/.ssh/id_rsa.pub --public-ip-sku Standard --nsg "" --subnet $subnetid