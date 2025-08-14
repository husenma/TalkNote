#!/bin/bash
# Deploy Azure Function for Speech Token Service
# Run this from macOS/Linux or Windows with Azure CLI installed

set -e

echo "🚀 Deploying Azure Function for Live Transcribe Speech Token Service"

# Configuration - Update these values
RESOURCE_GROUP="live-transcribe-rg"
LOCATION="eastus"
FUNCTION_APP_NAME="live-transcribe-func-$(date +%s)"
STORAGE_ACCOUNT="livetranscribe$(date +%s)"
SPEECH_SERVICE_NAME="live-transcribe-speech"

echo "📋 Using configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Function App: $FUNCTION_APP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Speech Service: $SPEECH_SERVICE_NAME"

# Create resource group
echo "🔧 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account for function app
echo "🔧 Creating storage account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create Speech service
echo "🔧 Creating Speech service..."
az cognitiveservices account create \
  --name $SPEECH_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind SpeechServices \
  --sku S0

# Get Speech service key and region
echo "🔑 Getting Speech service credentials..."
SPEECH_KEY=$(az cognitiveservices account keys list \
  --name $SPEECH_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "key1" -o tsv)

# Create Function App
echo "🔧 Creating Function App..."
az functionapp create \
  --resource-group $RESOURCE_GROUP \
  --consumption-plan-location $LOCATION \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4 \
  --name $FUNCTION_APP_NAME \
  --storage-account $STORAGE_ACCOUNT \
  --os-type Linux

# Configure app settings
echo "🔧 Setting app configuration..."
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
  "SPEECH_KEY=$SPEECH_KEY" \
  "SPEECH_REGION=$LOCATION"

# Deploy function code
echo "📦 Deploying function code..."
cd azure/functions
zip -r function.zip .
az functionapp deployment source config-zip \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --src function.zip
rm function.zip
cd ../..

# Get function URL
echo "🔗 Getting function URL..."
FUNCTION_URL="https://$FUNCTION_APP_NAME.azurewebsites.net"
FUNCTION_KEY=$(az functionapp function keys list \
  --function-name speech-token \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "default" -o tsv)

SPEECH_TOKEN_ENDPOINT="$FUNCTION_URL/api/speechToken?code=$FUNCTION_KEY"

echo "✅ Deployment complete!"
echo ""
echo "📋 Configuration for your iOS app:"
echo "  SPEECH_TOKEN_ENDPOINT: $SPEECH_TOKEN_ENDPOINT"
echo ""
echo "🔧 Next steps:"
echo "1. Update ios/LiveTranscribe/Info.plist with the SPEECH_TOKEN_ENDPOINT"
echo "2. Open Xcode project and build for App Store"
echo ""
echo "💾 Save these values:"
echo "  Function App: $FUNCTION_APP_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Speech Token Endpoint: $SPEECH_TOKEN_ENDPOINT"
