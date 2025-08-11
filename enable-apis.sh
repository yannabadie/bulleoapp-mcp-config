#!/bin/bash

# Enable all required GCP APIs for BulleoApp

set -e

PROJECT_ID="doublenumerique-yann"

echo "🔌 Enabling GCP APIs for BulleoApp"
echo "Project: $PROJECT_ID"
echo "=================================="
echo ""

# Set the project
gcloud config set project $PROJECT_ID

# List of required APIs
APIS=(
    # Core APIs
    "cloudresourcemanager.googleapis.com"     # Resource Manager
    "serviceusage.googleapis.com"              # Service Usage
    "iam.googleapis.com"                       # IAM
    
    # Storage & Database
    "firestore.googleapis.com"                 # Firestore
    "storage.googleapis.com"                   # Cloud Storage
    "firebase.googleapis.com"                  # Firebase
    "firebasedatabase.googleapis.com"          # Realtime Database
    
    # AI/ML APIs for BulleoApp
    "vision.googleapis.com"                    # Vision API (photo analysis)
    "speech.googleapis.com"                    # Speech-to-Text (voice journal)
    "texttospeech.googleapis.com"             # Text-to-Speech
    "translate.googleapis.com"                 # Translation
    "language.googleapis.com"                  # Natural Language
    "aiplatform.googleapis.com"               # Vertex AI
    
    # Healthcare specific
    "healthcare.googleapis.com"                # Healthcare API (FHIR)
    
    # Infrastructure
    "cloudfunctions.googleapis.com"            # Cloud Functions
    "run.googleapis.com"                       # Cloud Run
    "cloudbuild.googleapis.com"               # Cloud Build
    "containerregistry.googleapis.com"        # Container Registry
    "cloudscheduler.googleapis.com"           # Cloud Scheduler
    
    # Monitoring & Logging
    "logging.googleapis.com"                   # Cloud Logging
    "monitoring.googleapis.com"                # Cloud Monitoring
    "cloudtrace.googleapis.com"               # Cloud Trace
    "clouderrorreporting.googleapis.com"      # Error Reporting
    
    # Security
    "secretmanager.googleapis.com"            # Secret Manager
    "cloudkms.googleapis.com"                 # Cloud KMS
    
    # Billing & Cost Management
    "cloudbilling.googleapis.com"             # Cloud Billing
    "billingbudgets.googleapis.com"           # Billing Budgets
)

echo "📋 APIs to enable: ${#APIS[@]}"
echo ""

# Enable each API
for api in "${APIS[@]}"; do
    echo -n "Enabling $api... "
    if gcloud services enable $api --project=$PROJECT_ID 2>/dev/null; then
        echo "✅"
    else
        echo "⚠️ (might already be enabled)"
    fi
done

echo ""
echo "✅ All APIs enabled!"
echo ""

# List enabled APIs
echo "📊 Currently enabled APIs:"
echo "=========================="
gcloud services list --enabled --project=$PROJECT_ID --format="table(NAME,TITLE)" | head -20

echo ""
echo "To see all enabled APIs, run:"
echo "gcloud services list --enabled --project=$PROJECT_ID"