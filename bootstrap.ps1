$RESOURCE_GROUP="JmeterTest"
$STORAGE_ACCOUNT_NAME="jmeterteststore"
$LOCATION="westeurope"
$SHARE_NAME="jmetershare"
$VNET_NAME="JmeterTestVnet"
$SUBNET_NAME="container-snet"

az group create --location $LOCATION --name $RESOURCE_GROUP;
Write-Output "Created resource group"

# az network vnet create -g $RESOURCE_GROUP -n $VNET_NAME --address-prefix 10.0.0.0/16 --subnet-name $SUBNET_NAME --subnet-prefix 10.0.0.0/24
# Write-Output "Created vnet"

# Create the storage account with the parameters
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT_NAME --location $LOCATION --sku Standard_LRS
Write-Output "Created storage"

# Create the file share and get access key
az storage share create --name $SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME
Write-Output "Created file share"

$STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" --output tsv)
Write-Output $STORAGE_KEY

Write-Output "Creating container"
az container create `
    --resource-group $RESOURCE_GROUP `
    --name jmeterclient `
    --image justb4/jmeter:latest `
    --azure-file-volume-account-name $STORAGE_ACCOUNT_NAME `
    --azure-file-volume-account-key $STORAGE_KEY `
    --azure-file-volume-share-name $SHARE_NAME `
    --azure-file-volume-mount-path /jmeter/logs/ `
    --restart-policy never `
    --vnet $VNET_NAME `
    --subnet $SUBNET_NAME `
    --ip-address Private `
    --vnet-address-prefix 10.0.0.0/16 `
    --subnet-address-prefix 10.0.0.0/24 `

Write-Output "Created container"


docker run --volume "${volume_path}":${jmeter_path} jmeter \
  -n <any sequence of jmeter args> \
  -t ${jmeter_path}/<jmx_script> \
  -l ${jmeter_path}/tmp/result_${timestamp}.jtl \
  -j ${jmeter_path}/tmp/jmeter_${timestamp}.log