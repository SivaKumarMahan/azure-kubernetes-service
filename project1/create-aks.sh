#!/bin/bash

# Variables
RESOURCE_GROUP="test-rg"
LOCATION="centralindia"
AKS_NAME="aksdemo18"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 2 \
  --generate-ssh-keys

# Get AKS credentials to access the cluster
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Verify
kubectl get nodes

az aks get-credentials --resource-group test-rg --name aksdemo18 --overwrite-existing

kubectl config current-context

