#!/bin/bash

location='westcentralus'
subscription=''
resourcegroup=''
aciname=$resourcegroup"aci0"
uminame=$resourcegroup"umi0"

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

az configure -d location=$location subscription=$subscription group=$resourcegroup

az identity create -n $uminame
umiid=`az identity show -n $uminame --query id | sed "s/\"//g"`
#oid=`az identity show -n $uminame --query principalId | sed "s/\"//g"`
#az role assignment create --role contributor --assignee-object-id $oid --assignee-principal-type ServicePrincipal --scope $rgid

az container create -n $aciname --restart-policy OnFailure --image mcr.microsoft.com/azure-cli:latest --assign-identity $umiid  --command-line "/bin/bash -c 'az login --identity -u $umiid --allow-no-subscriptions; sleep infinity'"
az container exec -n  $aciname --exec-command "az account get-access-token"
az container exec -n  $aciname --exec-command "curl https://docs.microsoft.com/en-us/azure/container-instances/"