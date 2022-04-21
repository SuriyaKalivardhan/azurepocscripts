az group create -n suriyakmanagedapp --tags SkipAutoDeleteTill=2022-07-07 owner=suriyak@microsoft.com
az storage account create -n suriyakmanagedappstorage
export AZURE_STORAGE_ACCOUNT=suriyakmanagedappstorage AZURE_STORAGE_KEY=dummykey
az storage container create -n managedapp  --public-access container

az storage blob upload -f suriyaaacount.zip -c managedapp -n suriyaaacount.zip

Create a group: suriyakmanagedappgroup

az ad group show --group suriyakmanagedappgroup --query objectId --output tsv
fc6c6c7e-3600-4b55-8b99-9b1ab64079ea

az role definition list --name Owner --query [].name --output tsv
8e3af657-a8ff-443c-a75c-2fe8c4bcb635
az role definition list --name Contributor --query [].name --output tsv
b24988ac-6180-42a0-ab88-20f7382dd24c

az storage blob url --account-name suriyakmanagedappstorage --container-name managedapp --name app.zip --output tsv

az managedapp definition create --name SuriyaAccount --location eastus --lock-level ReadOnly --display-name "Suriya Account" --description "Suriya Account" --authorizations "fc6c6c7e-3600-4b55-8b99-9b1ab64079ea:8e3af657-a8ff-443c-a75c-2fe8c4bcb635" --package-file-uri https://suriyakmanagedappstorage.blob.core.windows.net/managedapp/suriyaaacount.zip
 
Use this sub to create resource: 7421b5fd-cf60-4260-b2a2-dbb76e98458b