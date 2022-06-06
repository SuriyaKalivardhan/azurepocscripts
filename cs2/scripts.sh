az configure -d subscription=ea4faa5b-5e44-4236-91f6-5483d5b17d14 group=suriyakcs2poc location=eastus2euap
az account set -s ea4faa5b-5e44-4236-91f6-5483d5b17d14
az group create -n suriyakcs2poc --tags owner=suriyak@microsoft.com skipAutoDeleteTill=2022-09-01
az cloud update --endpoint-resource-manager https://eastus2euap.management.azure.com
az cloud list
az rest -m put -b @profile.json -u https://eastus2euap.management.azure.com/subscriptions/ea4faa5b-5e44-4236-91f6-5483d5b17d14/resourceGroups/suriyakcs2poc/providers/Microsoft.ContainerInstance/containerGroupProfiles/suriyakcs2grouprofile4?api-version=2022-04-01-preview
az rest -m put -b @cs2.json -u https://eastus2euap.management.azure.com/subscriptions/ea4faa5b-5e44-4236-91f6-5483d5b17d14/resourceGroups/suriyakcs2poc/providers/Microsoft.ContainerInstance/containerScaleSets/suriyakcs2instance4?api-version=2022-04-01-preview

xargs -I %\n -P 50 curl 40.64.87.197:6001/metrics < <(printf '%s\n' {1..10000000})