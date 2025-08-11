#!/bin/bash

# Deploy BulleoApp MCP to Cloud Run

set -e

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-bulleoapp-prod}"
REGION="${GCP_REGION:-europe-west1}"
SERVICE_NAME="bulleoapp-mcp"
IMAGE_NAME="gcr.io/$PROJECT_ID/bulleoapp-mcp"

echo "🚀 Deploying BulleoApp MCP to Cloud Run..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Set the project
echo "📋 Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔌 Enabling required APIs..."
gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    containerregistry.googleapis.com \
    vision.googleapis.com \
    speech.googleapis.com \
    healthcare.googleapis.com \
    firestore.googleapis.com \
    storage.googleapis.com

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t $IMAGE_NAME -f Dockerfile .

# Configure Docker to use gcloud as a credential helper
echo "🔐 Configuring Docker authentication..."
gcloud auth configure-docker

# Push to Container Registry
echo "📤 Pushing image to Container Registry..."
docker push $IMAGE_NAME

# Create service account if it doesn't exist
echo "👤 Setting up service account..."
gcloud iam service-accounts create bulleoapp-mcp \
    --display-name="BulleoApp MCP Service Account" \
    2>/dev/null || echo "Service account already exists"

# Grant necessary roles
SERVICE_ACCOUNT="bulleoapp-mcp@${PROJECT_ID}.iam.gserviceaccount.com"
echo "🎯 Granting IAM roles..."

ROLES=(
    "roles/datastore.user"
    "roles/storage.objectAdmin"
    "roles/cloudvision.admin"
    "roles/cloudspeech.admin"
    "roles/healthcare.fhirResourceReader"
    "roles/logging.logWriter"
    "roles/monitoring.metricWriter"
)

for role in "${ROLES[@]}"; do
    echo "  Adding $role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="$role" \
        --quiet 2>/dev/null || true
done

# Deploy to Cloud Run
echo "☁️ Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --memory 2Gi \
    --cpu 2 \
    --max-instances 10 \
    --min-instances 1 \
    --set-env-vars="GCP_PROJECT_ID=$PROJECT_ID,FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-$PROJECT_ID}" \
    --service-account="$SERVICE_ACCOUNT"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --region $REGION \
    --format 'value(status.url)')

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📍 Service URL: $SERVICE_URL"
echo ""
echo "🔧 To use this MCP server remotely, update your Claude config:"
echo ""
cat << EOF
{
  "mcpServers": {
    "bulleoapp-gcp-remote": {
      "url": "$SERVICE_URL",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN"
      }
    }
  }
}
EOF
echo ""
echo "📊 View logs:"
echo "  gcloud run services logs read $SERVICE_NAME --region $REGION"
echo ""
echo "📈 Monitor performance:"
echo "  https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME"