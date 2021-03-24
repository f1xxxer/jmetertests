$ErrorActionPreference = "Stop"

$RESOURCE_GROUP="JmeterTest"
$STORAGE_ACCOUNT_NAME="jmeterteststore"
$LOCATION="westeurope"
$SHARE_NAME="jmetershare"
$SHARE_FOLDER="jmeter"
$SHARE_TEST_PLAN="test-plan.jmx"
$VNET_NAME="JmeterTestVnet"
$SUBNET_NAME="container-snet"
$CONTAINER_REGISTRY="yourregistry.azurecr.io"
$CONTAINER_REGISTRY_NAME="yourregistry"
$SERVER_IMAGE="jserver:latest"
$CONTROLLER_IMAGE="jcontroller:latest"
$CONTAINER_REGISTRY_USERNAME=(az acr credential show -n $CONTAINER_REGISTRY_NAME --query username)
$CONTAINER_REGISTRY_PWD=(az acr credential show -n $CONTAINER_REGISTRY_NAME --query passwords[0].value)
$WORKERS_AMOUNT=5

# Create Resource Group
Write-Output $LOCATION
az group create --location $LOCATION --name $RESOURCE_GROUP;
Write-Output "Created resource group"

# Create virtual network
az network vnet create -g $RESOURCE_GROUP -n $VNET_NAME --address-prefix 10.0.0.0/16 --subnet-name $SUBNET_NAME --subnet-prefix 10.0.0.0/24
Write-Output "Created vnet"

# Create the storage account with the parameters
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT_NAME --location $LOCATION --sku Standard_LRS
Write-Output "Created storage"

# Create the file share and get access key
az storage share create --name $SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME
Write-Output "Created file share"

$STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" --output tsv)
Write-Output $STORAGE_KEY

az storage directory create --name report `
                            --share-name $SHARE_NAME `
                            --account-name $STORAGE_ACCOUNT_NAME `
                            --account-key $STORAGE_KEY                            

# Upload Jmeter test plan
az storage file upload --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY --share-name $SHARE_NAME --source "C:\ttttt\demo.jmx" --path $SHARE_TEST_PLAN


# Build and push docker images for controller and server
Write-Output "Building image $CONTAINER_REGISTRY/$SERVER_IMAGE"
docker build -t "$CONTAINER_REGISTRY/$SERVER_IMAGE" -f .\Server\Dockerfile .
Write-Output "Pushing image $CONTAINER_REGISTRY/$SERVER_IMAGE"
docker push $CONTAINER_REGISTRY/$SERVER_IMAGE

Write-Output "Building image $CONTAINER_REGISTRY/$CONTROLLER_IMAGE"
docker build -t "$CONTAINER_REGISTRY/$CONTROLLER_IMAGE" -f .\Controller\Dockerfile .
Write-Output "Pushing image $CONTAINER_REGISTRY/$CONTROLLER_IMAGE"
docker push $CONTAINER_REGISTRY/$CONTROLLER_IMAGE

# Create and run container instances with Jmeter server image
$JServers = New-Object -TypeName "System.Collections.ArrayList"

For ($i=0; $i -le $WORKERS_AMOUNT; $i++) {
Write-Output "Creating container instance $i"
az container create `
    --resource-group $RESOURCE_GROUP `
    --name "jserver$i" `
    --image "$CONTAINER_REGISTRY/$SERVER_IMAGE" `
    --azure-file-volume-account-name $STORAGE_ACCOUNT_NAME `
    --azure-file-volume-account-key $STORAGE_KEY `
    --azure-file-volume-share-name $SHARE_NAME `
    --azure-file-volume-mount-path "/$SHARE_FOLDER/" `
    --restart-policy never `
    --vnet $VNET_NAME `
    --subnet $SUBNET_NAME `
    --ip-address Private `
    --vnet-address-prefix 10.0.0.0/16 `
    --subnet-address-prefix 10.0.0.0/24 `
    --registry-username $CONTAINER_REGISTRY_USERNAME `
    --registry-password $CONTAINER_REGISTRY_PWD `
    --environment-variables TEST_DIR=jmeter

$IP=(az container show --name "jserver$i" --resource-group $RESOURCE_GROUP --query ipAddress.ip --output tsv)
# Add running instance IP to ArrayList  
$JServers.Add($IP)
Write-Output "Created container instance $IP"
}

$Server_IPs=($JServers -join ",")

Write-Output "Creating controller"
# Create instance with Jmeter Controller image and run tests
az container create `
    --resource-group $RESOURCE_GROUP `
    --name "jcontroller" `
    --image "$CONTAINER_REGISTRY/$CONTROLLER_IMAGE" `
    --azure-file-volume-account-name $STORAGE_ACCOUNT_NAME `
    --azure-file-volume-account-key $STORAGE_KEY `
    --azure-file-volume-share-name $SHARE_NAME `
    --azure-file-volume-mount-path /jmeter/ `
    --restart-policy never `
    --vnet $VNET_NAME `
    --subnet $SUBNET_NAME `
    --ip-address Private `
    --vnet-address-prefix 10.0.0.0/16 `
    --subnet-address-prefix 10.0.0.0/24 `
    --registry-username $CONTAINER_REGISTRY_USERNAME `
    --registry-password $CONTAINER_REGISTRY_PWD `
    --environment-variables TEST_DIR=$SHARE_FOLDER TEST_FILE=$SHARE_TEST_PLAN SERVERS=$Server_IPs

Write-Output "Created controller and started running tests"

# $Test_status="Running"

# do {
#  $Test_status=(az container show --name jcontroller --resource-group JmeterTest --query instanceView.state)
#  Write-Progress -Activity "Running the tests..."
#  Start-Sleep 5 
# } while ($Test_status -ne "Succeeded")

# Write-Output "Finished tests."
#Maybe add copy comand here to get report folder from the file share 