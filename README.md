# 🚀 BulleoApp MCP Configuration

> Configuration MCP complète pour BulleoApp utilisant les serveurs MCP officiels de Google Cloud

## 📋 Architecture MCP pour BulleoApp

Cette configuration utilise les MCP officiels et communautaires existants pour une meilleure stabilité et maintenance :

1. **MCP Toolbox for Databases** (Officiel Google) - Pour Firebase/Firestore
2. **krzko/google-cloud-mcp** - Pour les services GCP (Vision, Speech, Storage, etc.)
3. **Cloud Run** - Pour héberger les MCP en production

## 🔧 Installation

### Étape 1 : Cloner les MCP nécessaires

```bash
# Créer le dossier des MCP
mkdir ~/bulleoapp-mcp
cd ~/bulleoapp-mcp

# Cloner le MCP Google Cloud complet
git clone https://github.com/krzko/google-cloud-mcp.git

# Cloner le MCP Toolbox for Databases (quand disponible publiquement)
# git clone https://github.com/GoogleCloudPlatform/mcp-database-toolbox.git
```

### Étape 2 : Configuration des Credentials GCP

```bash
# Télécharger les credentials depuis la console GCP
gcloud auth application-default login

# Ou utiliser un service account
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/bulleoapp-service-account.json"
```

### Étape 3 : Installation des dépendances

```bash
# Pour krzko/google-cloud-mcp
cd google-cloud-mcp
pnpm install
pnpm build
```

## 📝 Configuration Claude Desktop

Ajouter dans `~/Library/Application Support/Claude/claude_desktop_config.json` :

```json
{
  "mcpServers": {
    "bulleoapp-gcp": {
      "command": "node",
      "args": [
        "/Users/YOUR_USERNAME/bulleoapp-mcp/google-cloud-mcp/dist/index.js"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/YOUR_USERNAME/.config/gcloud/bulleoapp-credentials.json",
        "GCP_PROJECT_ID": "bulleoapp-prod",
        "FIREBASE_PROJECT_ID": "bulleoapp-firebase"
      }
    }
  }
}
```

## 🛠️ Services GCP Disponibles

### Via krzko/google-cloud-mcp

#### Vision AI (pour BulleoApp)
- `gcp-vision-analyze-image` - Analyse des photos de couches
- `gcp-vision-detect-text` - OCR pour médicaments
- `gcp-vision-detect-faces` - Analyse émotionnelle

#### Speech & Language
- `gcp-speech-transcribe` - Journal vocal
- `gcp-translate-text` - Traduction multi-langue

#### Storage
- `gcp-storage-upload` - Upload photos/vidéos
- `gcp-storage-list` - Lister les fichiers
- `gcp-storage-download` - Récupérer les fichiers

#### Firestore Operations
- Requêtes complexes
- Transactions
- Batch operations
- Real-time listeners

## 🏥 Cas d'Usage BulleoApp

### 1. Analyse de Couche Bébé
```javascript
// Utilise gcp-vision-analyze-image
const result = await mcp.call('gcp-vision-analyze-image', {
  image: base64Image,
  features: ['OBJECT_LOCALIZATION', 'IMAGE_PROPERTIES']
});
```

### 2. Journal Vocal de Grossesse
```javascript
// Utilise gcp-speech-transcribe
const transcript = await mcp.call('gcp-speech-transcribe', {
  audio: audioBuffer,
  languageCode: 'fr-FR'
});
```

### 3. Stockage Sécurisé Firestore
```javascript
// Via le MCP
const data = await mcp.call('firestore-query', {
  collection: 'pregnancy_tracking',
  where: [['userId', '==', userId]],
  orderBy: 'date',
  limit: 10
});
```

## 🚀 Déploiement sur Cloud Run

### Créer un Dockerfile pour le MCP

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copier les MCP
COPY google-cloud-mcp ./google-cloud-mcp

# Installer les dépendances
RUN cd google-cloud-mcp && npm install && npm run build

EXPOSE 8080

CMD ["node", "google-cloud-mcp/dist/index.js"]
```

### Déployer sur Cloud Run

```bash
# Build l'image
gcloud builds submit --tag gcr.io/bulleoapp-prod/mcp-server

# Déployer sur Cloud Run
gcloud run deploy bulleoapp-mcp \
  --image gcr.io/bulleoapp-prod/mcp-server \
  --platform managed \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars="GCP_PROJECT_ID=bulleoapp-prod,FIREBASE_PROJECT_ID=bulleoapp-firebase"
```

## 🔐 Sécurité & Conformité

### Configuration IAM

```bash
# Créer un service account dédié
gcloud iam service-accounts create bulleoapp-mcp \
  --display-name="BulleoApp MCP Service Account"

# Attribuer les rôles nécessaires
gcloud projects add-iam-policy-binding bulleoapp-prod \
  --member="serviceAccount:bulleoapp-mcp@bulleoapp-prod.iam.gserviceaccount.com" \
  --role="roles/healthcare.fhirResourceReader"

gcloud projects add-iam-policy-binding bulleoapp-prod \
  --member="serviceAccount:bulleoapp-mcp@bulleoapp-prod.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding bulleoapp-prod \
  --member="serviceAccount:bulleoapp-mcp@bulleoapp-prod.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### Conformité RGPD/HDS

- ✅ Données hébergées en Europe (europe-west1)
- ✅ Chiffrement au repos et en transit
- ✅ Audit logs activés
- ✅ Healthcare API pour données médicales
- ✅ Backup automatique quotidien

## 📊 Monitoring

```yaml
# monitoring-dashboard.yaml
apiVersion: monitoring.dashboard/v1
kind: Dashboard
metadata:
  name: bulleoapp-mcp-dashboard
spec:
  displayName: BulleoApp MCP Monitoring
  widgets:
    - title: MCP Request Rate
      xyChart:
        dataSets:
        - timeSeriesQuery:
            timeSeriesFilter:
              filter: resource.type="cloud_run_revision"
    - title: Vision API Usage
      scorecard:
        timeSeriesQuery:
          timeSeriesFilter:
            filter: metric.type="vision.googleapis.com/quota/used"
```

## 🧪 Tests

### Test de connexion

```bash
# Tester le MCP GCP
cd google-cloud-mcp
npx @modelcontextprotocol/inspector node dist/index.js
```

## 📚 Documentation

- [MCP Specification](https://modelcontextprotocol.io/)
- [Google Cloud MCP Documentation](https://cloud.google.com/run/docs/host-mcp-servers)
- [krzko/google-cloud-mcp](https://github.com/krzko/google-cloud-mcp)

## 🤝 Support

Pour toute question sur la configuration MCP de BulleoApp :
- Email : tech@bulleoapp.com
- Documentation : https://docs.bulleoapp.com/mcp

## 📝 License

MIT License - BulleoApp 2025