#!/bin/bash

location='eastus'
subscription=''
resourcegroup=''

if [ -z $1 ] || [ -z $2 ]; then
    echo "No Subscription or resource group passed, exiting.."
    echo "Usage ./aciwithazcli.sh <subscriptionid> <resourcegroup>"
    exit 1
else
    subscription=$1
    resourcegroup=$2
fi

az account set -s $subscription
if [ $? != 0 ]; then
    exit 1
fi

rgid=`az group show -n $resourcegroup --query id | sed "s/\"//g"`
if [ rgid == '' ]; then
    echo "Resource group $resourcegroup doesnt exist, please create and retry"
    exit 2
fi

set -x
aciname=$resourcegroup"aci0"
uminame=$resourcegroup"umi0"
nsgname=$resourcegroup"nsg0"
vnetname=$resourcegroup"vnet0"
subnetname=$resourcegroup"acisubnet0"
set +x
az configure -d location=$location subscription=$subscription group=$resourcegroup

az identity create -n $uminame
umiid=`az identity show -n $uminame --query id | sed "s/\"//g"`
#oid=`az identity show -n $uminame --query principalId | sed "s/\"//g"`
#az role assignment create --role contributor --assignee-object-id $oid --assignee-principal-type ServicePrincipal --scope $rgid

az network nsg create -n $nsgname
az network nsg rule create --nsg-name $nsgname -n AllowInternetOutbound --priority 4096 --access Allow --protocol '*' --source-address-prefixes '*' --destination-address-prefixes Internet --destination-port-ranges '*' --direction Outbound
nsgid=`az network nsg show -n $nsgname --query id | sed "s/\"//g"`
az network vnet create -n $vnetname --address-prefix 10.0.0.0/16 --subnet-name $subnetname --subnet-prefix 10.0.0.0/24 --nsg $nsgid
subnetid=`az network vnet subnet show --vnet-name $vnetname -n $subnetname --query id | sed "s/\"//g"`

az container create -n $aciname --restart-policy OnFailure --image mcr.microsoft.com/azure-cli:latest --assign-identity $umiid --subnet $subnetid --command-line "/bin/bash -c 'az login --identity -u $umiid --allow-no-subscriptions; sleep infinity'"
az container logs -n $aciname
az container exec -n  $aciname --exec-command "az account get-access-token"
az container exec -n  $aciname --exec-command "curl https://docs.microsoft.com/en-us/azure/container-instances/"