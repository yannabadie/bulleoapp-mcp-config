# 🚀 BulleoApp MCP Configuration

> Configuration MCP complète pour BulleoApp utilisant les serveurs MCP officiels de Google Cloud

## ⚠️ Configuration Importante

**Projet GCP :** `doublenumerique-yann`

## 📋 Architecture MCP pour BulleoApp

Cette configuration utilise les MCP officiels et communautaires existants pour une meilleure stabilité et maintenance :

1. **krzko/google-cloud-mcp** - Pour les services GCP (Vision, Speech, Storage, Firestore, etc.)
2. **MCP Toolbox for Databases** (Officiel Google) - Pour Firebase/Firestore (quand disponible)
3. **Cloud Run** - Pour héberger les MCP en production

## 🔧 Installation Rapide

### Option 1 : Installation automatique (Recommandé)

```bash
# Cloner le repository
git clone https://github.com/yannabadie/bulleoapp-mcp-config.git
cd bulleoapp-mcp-config

# Rendre les scripts exécutables
chmod +x setup.sh diagnose.sh

# Lancer l'installation
./setup.sh
```

### Option 2 : Installation manuelle

```bash
# 1. Créer le dossier MCP
mkdir ~/bulleoapp-mcp
cd ~/bulleoapp-mcp

# 2. Cloner google-cloud-mcp
git clone https://github.com/krzko/google-cloud-mcp.git
cd google-cloud-mcp

# 3. Installer les dépendances
npm install

# 4. Builder le projet
npm run build

# 5. Configurer GCP
gcloud config set project doublenumerique-yann
gcloud auth application-default login
```

## 🔍 Diagnostic des Problèmes

Si le MCP n'apparaît pas dans Claude après l'installation :

```bash
# Lancer le script de diagnostic
./diagnose.sh
```

### Checklist de Vérification

1. **Claude est-il complètement fermé ?**
   - ❌ Ne pas juste fermer la fenêtre
   - ✅ Sur macOS : Cmd+Q ou Claude > Quitter Claude
   - ✅ Sur Windows : Clic droit icône système > Quitter
   - ✅ Sur Linux : Fermer toutes les fenêtres Claude

2. **Le fichier de configuration existe-t-il ?**
   - macOS : `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Linux : `~/.config/Claude/claude_desktop_config.json`
   - Windows : `%APPDATA%/Claude/claude_desktop_config.json`

3. **Vérifier le contenu du fichier :**
```bash
# Sur macOS/Linux
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Le fichier doit contenir :
```json
{
  "mcpServers": {
    "bulleoapp-gcp": {
      "command": "node",
      "args": [
        "/Users/VOTRE_USER/bulleoapp-mcp/google-cloud-mcp/dist/index.js"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/VOTRE_USER/.config/gcloud/bulleoapp-credentials.json",
        "GCP_PROJECT_ID": "doublenumerique-yann",
        "FIREBASE_PROJECT_ID": "doublenumerique-yann"
      }
    }
  }
}
```

4. **Le MCP est-il construit ?**
```bash
ls ~/bulleoapp-mcp/google-cloud-mcp/dist/index.js
# Si le fichier n'existe pas :
cd ~/bulleoapp-mcp/google-cloud-mcp
npm run build
```

5. **Les credentials sont-ils présents ?**
```bash
ls ~/.config/gcloud/bulleoapp-credentials.json
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

## 🏥 Exemples de Commandes dans Claude

Une fois le MCP configuré, vous pouvez utiliser ces commandes dans Claude :

### Commandes GCP Générales
- "Liste mes buckets Cloud Storage dans doublenumerique-yann"
- "Montre mes collections Firestore"
- "Quels services GCP sont activés dans mon projet ?"

### Commandes BulleoApp Spécifiques
- "Analyse cette photo de couche pour détecter des anomalies"
- "Transcris mon journal vocal et identifie les symptômes"
- "Vérifie si ce médicament est compatible avec ma grossesse"
- "Génère ma checklist valise maternité pour juillet"
- "Crée un rapport de mon cycle PMA actuel"

## 🐛 Résolution des Problèmes Courants

### Le MCP n'apparaît pas dans Claude

1. **Assurez-vous que Claude est complètement fermé**
   ```bash
   # Sur macOS, vérifier qu'aucun processus Claude ne tourne
   ps aux | grep Claude
   ```

2. **Recréer le fichier de configuration**
   ```bash
   ./setup.sh
   ```

3. **Tester le MCP manuellement**
   ```bash
   cd ~/bulleoapp-mcp/google-cloud-mcp
   npx @modelcontextprotocol/inspector node dist/index.js
   ```

### Erreur "Project not found"

```bash
# Vérifier le projet actuel
gcloud config get-value project

# Le définir correctement
gcloud config set project doublenumerique-yann
```

### Erreur de permissions

```bash
# Recréer le service account
gcloud iam service-accounts create bulleoapp-mcp \
    --display-name="BulleoApp MCP Service Account" \
    --project="doublenumerique-yann"

# Réattribuer les permissions
./setup.sh
```

## 🚀 Déploiement sur Cloud Run (Production)

```bash
# Configurer le projet
export GCP_PROJECT_ID=doublenumerique-yann
export GCP_REGION=europe-west1

# Déployer
./deploy.sh
```

## 🔐 Sécurité & Conformité

### Configuration IAM Minimale

Le service account `bulleoapp-mcp` a uniquement les permissions nécessaires :
- ✅ `roles/datastore.user` - Accès Firestore
- ✅ `roles/storage.objectAdmin` - Gestion des fichiers
- ✅ `roles/cloudvision.admin` - Analyse d'images
- ✅ `roles/cloudspeech.admin` - Transcription audio
- ✅ `roles/logging.logWriter` - Logs
- ✅ `roles/monitoring.metricWriter` - Métriques

### Conformité RGPD/HDS

- ✅ Données hébergées en Europe (europe-west1)
- ✅ Chiffrement au repos et en transit
- ✅ Audit logs activés
- ✅ Healthcare API pour données médicales
- ✅ Backup automatique quotidien

## 📊 Monitoring

Pour surveiller l'utilisation :

```bash
# Voir les logs du MCP
gcloud logging read "resource.type=cloud_function" --limit 50

# Vérifier les quotas Vision API
gcloud compute project-info describe --project=doublenumerique-yann
```

## 📚 Documentation

- [MCP Specification](https://modelcontextprotocol.io/)
- [Google Cloud MCP Documentation](https://cloud.google.com/run/docs/host-mcp-servers)
- [krzko/google-cloud-mcp](https://github.com/krzko/google-cloud-mcp)

## 🤝 Support

Pour toute question sur la configuration MCP de BulleoApp :
- Email : tech@bulleoapp.com
- Issues : [GitHub Issues](https://github.com/yannabadie/bulleoapp-mcp-config/issues)

## 📝 License

MIT License - BulleoApp 2025