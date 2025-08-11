#!/bin/bash

# Initialize Firebase for BulleoApp

echo "🔥 Initializing Firebase for BulleoApp"
echo "======================================"
echo ""

PROJECT_ID="doublenumerique-yann"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
fi

echo "🔐 Authenticating with Firebase..."
firebase login

echo ""
echo "📋 Setting up Firebase project: $PROJECT_ID"
firebase use $PROJECT_ID

echo ""
echo "🛠️ Initializing Firebase services..."
echo ""

# Create firebase.json if it doesn't exist
if [ ! -f "firebase.json" ]; then
    cat > firebase.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions",
    "predeploy": "npm --prefix \"$RESOURCE_DIR\" run build"
  },
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
EOF
    echo "✅ Created firebase.json"
fi

# Create Firestore rules for BulleoApp
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Pregnancy tracking data
    match /pregnancy_tracking/{userId}/records/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // PMA cycles data
    match /pma_cycles/{userId}/cycles/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Voice journals
    match /voice_journals/{userId}/entries/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Feeding sessions
    match /feeding_sessions/{document=**} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Diaper logs
    match /diaper_logs/{document=**} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Checklists
    match /checklists/{userId}/lists/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Medication safety (read-only for all authenticated users)
    match /medication_safety/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
    
    // Community features (optional)
    match /community_posts/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
EOF
echo "✅ Created Firestore security rules"

# Create Storage rules
cat > storage.rules << 'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /users/{userId}/profile/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Medical documents (private)
    match /users/{userId}/medical/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Baby photos (private)
    match /users/{userId}/baby_photos/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Voice recordings (private)
    match /users/{userId}/voice_recordings/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Diaper analysis photos (private)
    match /users/{userId}/diaper_photos/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports and exports
    match /users/{userId}/reports/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
EOF
echo "✅ Created Storage security rules"

# Create Firestore indexes
cat > firestore.indexes.json << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "feeding_sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "diaper_logs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "pma_cycles",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "voice_journals",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF
echo "✅ Created Firestore indexes"

echo ""
echo "📊 Current Firebase configuration:"
firebase projects:list

echo ""
echo "🚀 Deploying Firebase rules..."
firebase deploy --only firestore:rules,storage:rules,firestore:indexes

echo ""
echo "✅ Firebase initialization complete!"
echo ""
echo "Next steps:"
echo "1. Enable Authentication in Firebase Console"
echo "2. Add authorized domains for OAuth"
echo "3. Configure Firebase in your Flutter/React app"
echo ""
echo "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"