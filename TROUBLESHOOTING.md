# 🔧 Troubleshooting Guide - BulleoApp MCP

## ❗ Le MCP n'apparaît pas dans Claude

### Solution Rapide

```bash
# 1. Télécharger et exécuter le quick fix
git clone https://github.com/yannabadie/bulleoapp-mcp-config.git
cd bulleoapp-mcp-config
chmod +x quickfix.sh
./quickfix.sh

# 2. Quitter COMPLÈTEMENT Claude (Cmd+Q sur Mac)

# 3. Redémarrer Claude
```

### Vérification Manuelle

#### 1. Localiser le fichier de configuration Claude

Le fichier doit être à l'un de ces emplacements :

- **macOS** : `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux** : `~/.config/Claude/claude_desktop_config.json`  
- **Windows** : `%APPDATA%\Claude\claude_desktop_config.json`

#### 2. Vérifier le contenu du fichier

```bash
# Sur macOS
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | python3 -m json.tool
```

Le fichier DOIT contenir EXACTEMENT (remplacez YOUR_USERNAME par votre nom d'utilisateur) :

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
        "GCP_PROJECT_ID": "doublenumerique-yann",
        "FIREBASE_PROJECT_ID": "doublenumerique-yann"
      }
    }
  }
}
```

#### 3. Points Critiques à Vérifier

✅ **Les chemins sont-ils absolus ?**
- ❌ Mauvais : `~/bulleoapp-mcp/...`
- ✅ Bon : `/Users/votrenom/bulleoapp-mcp/...`

✅ **Le projet GCP est-il correct ?**
- Doit être : `doublenumerique-yann`

✅ **Le fichier index.js existe-t-il ?**
```bash
ls -la ~/bulleoapp-mcp/google-cloud-mcp/dist/index.js
```

✅ **Les credentials existent-ils ?**
```bash
ls -la ~/.config/gcloud/bulleoapp-credentials.json
```

### Si le fichier de config n'existe pas

```bash
# Créer le dossier
mkdir -p ~/Library/Application\ Support/Claude

# Créer le fichier (remplacez YOUR_USERNAME)
cat > ~/Library/Application\ Support/Claude/claude_desktop_config.json << 'EOF'
{
  "mcpServers": {
    "bulleoapp-gcp": {
      "command": "node",
      "args": [
        "/Users/YOUR_USERNAME/bulleoapp-mcp/google-cloud-mcp/dist/index.js"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/YOUR_USERNAME/.config/gcloud/bulleoapp-credentials.json",
        "GCP_PROJECT_ID": "doublenumerique-yann",
        "FIREBASE_PROJECT_ID": "doublenumerique-yann"
      }
    }
  }
}
EOF
```

## ❗ Erreur "Cannot find module"

### Solution

```bash
cd ~/bulleoapp-mcp/google-cloud-mcp
npm install
npm run build
```

## ❗ Erreur "Permission denied"

### Solution

```bash
# Donner les permissions d'exécution
chmod +x ~/bulleoapp-mcp/google-cloud-mcp/dist/index.js

# Vérifier les permissions du fichier de credentials
chmod 600 ~/.config/gcloud/bulleoapp-credentials.json
```

## ❗ Erreur "Project not found"

### Solution

```bash
# Configurer le bon projet
gcloud config set project doublenumerique-yann

# Se réauthentifier
gcloud auth application-default login
```

## ❗ Claude se ferme ou crash

### Causes possibles

1. **Erreur dans le fichier JSON**
   ```bash
   # Valider le JSON
   python3 -m json.tool ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

2. **Chemin incorrect**
   - Vérifiez que tous les chemins sont absolus et corrects

3. **Node.js manquant ou incompatible**
   ```bash
   # Vérifier la version (doit être 18+)
   node --version
   ```

## ❗ Le MCP apparaît mais ne fonctionne pas

### Test manuel du MCP

```bash
cd ~/bulleoapp-mcp/google-cloud-mcp

# Définir les variables d'environnement
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/bulleoapp-credentials.json
export GCP_PROJECT_ID=doublenumerique-yann

# Tester le MCP
npx @modelcontextprotocol/inspector node dist/index.js
```

### Vérifier les APIs GCP activées

```bash
# Lister les APIs activées
gcloud services list --enabled --project=doublenumerique-yann

# Activer les APIs nécessaires
gcloud services enable \
    vision.googleapis.com \
    speech.googleapis.com \
    firestore.googleapis.com \
    storage.googleapis.com \
    --project=doublenumerique-yann
```

## 📊 Script de Diagnostic Complet

```bash
# Télécharger et exécuter le diagnostic
./diagnose.sh
```

Ce script vérifie :
- ✅ Installation de Node.js
- ✅ Installation de gcloud
- ✅ Présence du MCP
- ✅ Fichier de configuration Claude
- ✅ Credentials GCP
- ✅ Projet GCP configuré

## 🆘 Support

Si aucune solution ne fonctionne :

1. **Capturez la sortie du diagnostic**
   ```bash
   ./diagnose.sh > diagnostic_output.txt 2>&1
   ```

2. **Créez une issue sur GitHub**
   - [Créer une issue](https://github.com/yannabadie/bulleoapp-mcp-config/issues/new)
   - Joignez le fichier `diagnostic_output.txt`

3. **Informations à fournir**
   - OS (macOS/Linux/Windows) et version
   - Version de Claude Desktop
   - Version de Node.js (`node --version`)
   - Erreur exacte ou comportement observé

## 💡 Tips

### Forcer le rechargement de Claude

Sur macOS :
```bash
# Tuer tous les processus Claude
pkill -f Claude

# Nettoyer le cache
rm -rf ~/Library/Caches/Claude*

# Redémarrer
open -a Claude
```

### Logs de Claude

Pour voir les logs de Claude (peut aider au debug) :
```bash
# macOS
tail -f ~/Library/Logs/Claude/main.log
```

### Réinitialisation complète

Si rien ne fonctionne :
```bash
# Sauvegarder la config actuelle
cp ~/Library/Application\ Support/Claude/claude_desktop_config.json ~/claude_config_backup.json

# Supprimer tout
rm -rf ~/bulleoapp-mcp
rm -rf ~/Library/Application\ Support/Claude
rm -rf ~/.config/gcloud/bulleoapp-credentials.json

# Réinstaller depuis zéro
git clone https://github.com/yannabadie/bulleoapp-mcp-config.git
cd bulleoapp-mcp-config
./setup.sh
```