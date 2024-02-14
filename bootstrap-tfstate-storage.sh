#!/bin/bash

subscription=$1
resource_group=$2
accname=$3

az storage account create \
    --subscription $subscription \
    --name $accname \
    --resource-group $resource_group \
    --kind StorageV2 \
    --sku Standard_LRS \
    --https-only true \
    --allow-blob-public-access false \

az storage container create \
    --subscription $subscription \
    --account-name $accname \
    --name tfstate \

