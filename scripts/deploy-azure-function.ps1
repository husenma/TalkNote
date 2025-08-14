# Deploy Azure Function for Speech Token Service (PowerShell)
# Run this from Windows with Azure CLI installed

# Configuration - Update these values
$RESOURCE_GROUP = "live-transcribe-rg"
$LOCATION = "eastus"
$FUNCTION_APP_NAME = "live-transcribe-func-$(Get-Date -Format 'yyyyMMddHHmmss')"
$STORAGE_ACCOUNT = "livetranscribe$(Get-Date -Format 'yyyyMMddHHmmss')"
$SPEECH_SERVICE_NAME = "live-transcribe-speech"

Write-Host "🚀 Deploying Azure Function for Live Transcribe Speech Token Service" -ForegroundColor Green

Write-Host "📋 Using configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  Location: $LOCATION"
Write-Host "  Function App: $FUNCTION_APP_NAME"
Write-Host "  Storage Account: $STORAGE_ACCOUNT"
Write-Host "  Speech Service: $SPEECH_SERVICE_NAME"

# Check if Azure CLI is installed
if (!(Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Installing..." -ForegroundColor Red
    Write-Host "Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows"
    Write-Host "Or run: winget install Microsoft.AzureCLI"
    exit 1
}

# Login check
Write-Host "🔐 Checking Azure login..." -ForegroundColor Yellow
$loginCheck = az account show 2>$null
if (!$loginCheck) {
    Write-Host "❌ Not logged in to Azure. Please run: az login" -ForegroundColor Red
    exit 1
}

try {
    # Create resource group
    Write-Host "🔧 Creating resource group..." -ForegroundColor Yellow
    az group create --name $RESOURCE_GROUP --location $LOCATION

    # Create storage account for function app
    Write-Host "🔧 Creating storage account..." -ForegroundColor Yellow
    az storage account create `
        --name $STORAGE_ACCOUNT `
        --resource-group $RESOURCE_GROUP `
        --location $LOCATION `
        --sku Standard_LRS

    # Create Speech service
    Write-Host "🔧 Creating Speech service..." -ForegroundColor Yellow
    az cognitiveservices account create `
        --name $SPEECH_SERVICE_NAME `
        --resource-group $RESOURCE_GROUP `
        --location $LOCATION `
        --kind SpeechServices `
        --sku S0

    # Get Speech service key and region
    Write-Host "🔑 Getting Speech service credentials..." -ForegroundColor Yellow
    $SPEECH_KEY = az cognitiveservices account keys list `
        --name $SPEECH_SERVICE_NAME `
        --resource-group $RESOURCE_GROUP `
        --query "key1" -o tsv

    # Create Function App
    Write-Host "🔧 Creating Function App..." -ForegroundColor Yellow
    az functionapp create `
        --resource-group $RESOURCE_GROUP `
        --consumption-plan-location $LOCATION `
        --runtime node `
        --runtime-version 20 `
        --functions-version 4 `
        --name $FUNCTION_APP_NAME `
        --storage-account $STORAGE_ACCOUNT `
        --os-type Linux

    # Configure app settings
    Write-Host "🔧 Setting app configuration..." -ForegroundColor Yellow
    az functionapp config appsettings set `
        --name $FUNCTION_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --settings "SPEECH_KEY=$SPEECH_KEY" "SPEECH_REGION=$LOCATION"

    # Deploy function code
    Write-Host "📦 Deploying function code..." -ForegroundColor Yellow
    Set-Location azure/functions
    Compress-Archive -Path * -DestinationPath function.zip -Force
    az functionapp deployment source config-zip `
        --name $FUNCTION_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --src function.zip
    Remove-Item function.zip
    Set-Location ../..

    # Wait for deployment to complete
    Write-Host "⏳ Waiting for deployment to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # Get function URL
    Write-Host "🔗 Getting function URL..." -ForegroundColor Yellow
    $FUNCTION_URL = "https://$FUNCTION_APP_NAME.azurewebsites.net"
    $FUNCTION_KEY = az functionapp function keys list `
        --function-name speech-token `
        --name $FUNCTION_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --query "default" -o tsv

    $SPEECH_TOKEN_ENDPOINT = "$FUNCTION_URL/api/speechToken?code=$FUNCTION_KEY"

    Write-Host "✅ Deployment complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Configuration for your iOS app:" -ForegroundColor Cyan
    Write-Host "  SPEECH_TOKEN_ENDPOINT: $SPEECH_TOKEN_ENDPOINT" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Copy the SPEECH_TOKEN_ENDPOINT above"
    Write-Host "2. Update ios/LiveTranscribe/Info.plist with this endpoint"
    Write-Host "3. Use a Mac or cloud Mac service to build for App Store"
    Write-Host ""
    Write-Host "💾 Save these values:" -ForegroundColor Cyan
    Write-Host "  Function App: $FUNCTION_APP_NAME"
    Write-Host "  Resource Group: $RESOURCE_GROUP"
    Write-Host "  Speech Token Endpoint: $SPEECH_TOKEN_ENDPOINT"

    # Test the endpoint
    Write-Host ""
    Write-Host "🧪 Testing endpoint..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri $SPEECH_TOKEN_ENDPOINT -Method Get
        if ($response.token -and $response.region) {
            Write-Host "✅ Endpoint test successful!" -ForegroundColor Green
            Write-Host "  Token length: $($response.token.Length) characters"
            Write-Host "  Region: $($response.region)"
        } else {
            Write-Host "⚠️ Endpoint responded but format may be incorrect" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Endpoint test failed. May need a few minutes to become available." -ForegroundColor Yellow
        Write-Host "   Try testing manually: $SPEECH_TOKEN_ENDPOINT"
    }

} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
