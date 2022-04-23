az configure -d group=suriyakmanagedapp
az storage blob upload -f huggingface.zip -c managedapp -n huggingface.zip

az managedapp definition create --name AzureHuggingFace --location eastus --lock-level ReadOnly --display-name "Azure Hugging Face" --description "Azure Hugging Face2" --authorizations "fc6c6c7e-3600-4b55-8b99-9b1ab64079ea:8e3af657-a8ff-443c-a75c-2fe8c4bcb635" --package-file-uri https://suriyakmanagedappstorage.blob.core.windows.net/managedapp/huggingface3.zip


az managedapp definition create --name AzureHuggingFace --location eastus --lock-level None --display-name "Azure Hugging Face" --description "Azure Hugging Face" --authorizations "fc6c6c7e-3600-4b55-8b99-9b1ab64079ea:8e3af657-a8ff-443c-a75c-2fe8c4bcb635" --package-file-uri https://suriyakmanagedappstorage.blob.core.windows.net/managedapp/huggingface.zip
 