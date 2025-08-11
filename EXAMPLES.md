# 🏥 BulleoApp MCP - Exemples d'Utilisation

## Workflows Automatisés avec Claude

Ces exemples montrent comment utiliser les MCP configurés pour automatiser les fonctionnalités de BulleoApp directement via Claude.

## 📸 Analyse de Couche Bébé

### Commande Claude
```
"J'ai pris une photo de la couche de mon bébé. Peux-tu l'analyser pour détecter d'éventuelles anomalies ?"
```

### Workflow MCP Automatique
```javascript
// 1. Vision API analyse l'image
const analysis = await gcp.visionAnalyze(image, {
  features: ['OBJECT_LOCALIZATION', 'IMAGE_PROPERTIES', 'SAFE_SEARCH_DETECTION']
});

// 2. IA détermine la couleur et consistance
const healthAnalysis = {
  color: detectStoolColor(analysis),
  consistency: detectConsistency(analysis),
  anomalies: detectAnomalies(analysis)
};

// 3. Sauvegarde dans Firestore
await firestore.collection('diaper_logs').add({
  userId: userId,
  timestamp: new Date(),
  analysis: healthAnalysis,
  imageUrl: storageUrl,
  alerts: generateAlerts(healthAnalysis)
});

// 4. Notification si anomalie détectée
if (healthAnalysis.alerts.includes('urgent')) {
  await sendUrgentNotification(userId, healthAnalysis.alerts);
}
```

## 🎤 Journal Vocal de Grossesse

### Commande Claude
```
"Voici mon journal vocal du jour. Peux-tu le transcrire et analyser les symptômes mentionnés ?"
```

### Workflow MCP Automatique
```javascript
// 1. Transcription avec Speech-to-Text
const transcript = await gcp.speechTranscribe(audioBuffer, {
  languageCode: 'fr-FR',
  model: 'medical_dictation'
});

// 2. Analyse du contenu avec Vertex AI
const analysis = await vertexAI.analyze(transcript, {
  extractSymptoms: true,
  detectMood: true,
  findMedications: true,
  checkUrgency: true
});

// 3. Stockage structuré
await firestore.collection('voice_journals').add({
  userId: userId,
  date: new Date(),
  transcript: transcript,
  symptoms: analysis.symptoms,
  mood: analysis.moodScore,
  medications: analysis.medications,
  urgencyLevel: analysis.urgency
});

// 4. Génération de recommandations
const recommendations = await generateHealthRecommendations(analysis);
```

## 💊 Scan de Médicaments

### Commande Claude
```
"J'ai pris en photo cette boîte de médicament. Est-ce compatible avec ma grossesse ?"
```

### Workflow MCP Automatique
```javascript
// 1. OCR avec Vision API
const text = await gcp.visionDetectText(medicationImage);

// 2. Extraction des informations
const medication = {
  name: extractMedicationName(text),
  activeSubstance: extractActiveSubstance(text),
  dosage: extractDosage(text)
};

// 3. Vérification dans la base de données
const safety = await firestore
  .collection('medication_safety')
  .where('name', '==', medication.name)
  .get();

// 4. Analyse de compatibilité grossesse
const compatibility = await checkPregnancyCompatibility(medication);

// 5. Alternatives si incompatible
if (!compatibility.safe) {
  const alternatives = await findSafeAlternatives(medication);
  return { 
    safe: false, 
    reason: compatibility.reason,
    alternatives: alternatives 
  };
}
```

## 📊 Suivi PMA Complet

### Commande Claude
```
"Génère un rapport complet de mon cycle PMA actuel avec tous mes résultats d'analyses"
```

### Workflow MCP Automatique
```javascript
// 1. Récupération des données du cycle
const cycleData = await firestore
  .collection('pma_cycles')
  .where('userId', '==', userId)
  .where('status', '==', 'active')
  .get();

// 2. Extraction des résultats labo (OCR si nécessaire)
const labResults = await Promise.all(
  cycleData.docs.map(async doc => {
    if (doc.data().labPdfUrl) {
      return await extractLabResults(doc.data().labPdfUrl);
    }
    return doc.data().labResults;
  })
);

// 3. Génération du rapport avec Vertex AI
const report = await vertexAI.generateReport({
  cycleData: cycleData,
  labResults: labResults,
  template: 'pma_comprehensive'
});

// 4. Création du PDF
const pdfBuffer = await generatePDF(report);

// 5. Stockage et partage
const pdfUrl = await gcp.storageUpload(pdfBuffer, {
  bucket: 'bulleoapp-reports',
  path: `pma/${userId}/report-${Date.now()}.pdf`
});

return { reportUrl: pdfUrl, summary: report.summary };
```

## 📝 Valise Maternité Personnalisée

### Commande Claude
```
"Crée ma checklist de valise maternité. J'accouche en juillet à la maternité Port-Royal"
```

### Workflow MCP Automatique
```javascript
// 1. Récupération du contexte
const context = {
  dueDate: await getUserDueDate(userId),
  season: 'summer',
  hospital: 'Port-Royal',
  firstBaby: await isFirstBaby(userId)
};

// 2. Génération de la checklist personnalisée
const checklist = await vertexAI.generateChecklist({
  type: 'maternity_bag',
  context: context,
  includeHospitalSpecific: true
});

// 3. Sauvegarde dans Firestore
const checklistDoc = await firestore.collection('checklists').add({
  userId: userId,
  type: 'maternity',
  items: checklist.items,
  categories: checklist.categories,
  createdAt: new Date()
});

// 4. Configuration des rappels
await cloudScheduler.create({
  name: `maternity-reminder-${userId}`,
  schedule: '0 9 * * *', // Tous les jours à 9h
  target: 'checkMaternityProgress',
  params: { userId, checklistId: checklistDoc.id }
});
```

## 🏠 Analyse de la Chambre Bébé

### Commande Claude
```
"J'ai filmé la chambre de bébé. Peux-tu vérifier si tout est sécurisé ?"
```

### Workflow MCP Automatique
```javascript
// 1. Extraction des frames de la vidéo
const frames = await extractVideoFrames(videoUrl, { 
  count: 10,
  format: 'base64' 
});

// 2. Analyse de sécurité avec Vision AI
const safetyAnalysis = await Promise.all(
  frames.map(frame => gcp.visionAnalyze(frame, {
    features: ['OBJECT_LOCALIZATION', 'SAFE_SEARCH_DETECTION']
  }))
);

// 3. Détection des dangers potentiels
const hazards = detectNurseryHazards(safetyAnalysis);

// 4. Score de sécurité et recommandations
const safetyScore = calculateSafetyScore(hazards);
const recommendations = generateSafetyRecommendations(hazards);

// 5. Rapport détaillé
return {
  score: safetyScore,
  hazards: hazards,
  recommendations: recommendations,
  urgentActions: hazards.filter(h => h.priority === 'urgent')
};
```

## 🚨 Alertes et Notifications Intelligentes

### Configuration des Alertes Automatiques
```javascript
// Configuration dans Firestore Rules
const alertRules = {
  // Alerte poids
  weightAlert: {
    condition: 'weight_change > 2kg in 1 week',
    action: 'notify_doctor',
    urgency: 'medium'
  },
  
  // Alerte tension
  bloodPressureAlert: {
    condition: 'systolic > 140 OR diastolic > 90',
    action: 'immediate_consultation',
    urgency: 'high'
  },
  
  // Alerte mouvement bébé
  movementAlert: {
    condition: 'no_movement_recorded > 12 hours',
    action: 'check_with_user',
    urgency: 'medium'
  }
};
```

## 📱 Intégration avec Doctolib

### Commande Claude
```
"J'ai des contractions régulières. Peux-tu prendre un RDV urgent avec ma sage-femme ?"
```

### Workflow MCP Automatique
```javascript
// 1. Analyse de l'urgence
const urgency = await analyzeSymptomUrgency('contractions régulières');

// 2. Recherche de créneaux disponibles
const availableSlots = await doctolibAPI.searchAppointments({
  practitioner: userProfile.midwife,
  urgency: urgency.level,
  maxDelay: urgency.maxHours
});

// 3. Réservation automatique
if (availableSlots.length > 0 && urgency.level === 'high') {
  const appointment = await doctolibAPI.book({
    slot: availableSlots[0],
    patientId: userId,
    reason: 'Contractions régulières'
  });
  
  // 4. Notification
  await sendNotification(userId, {
    title: 'RDV confirmé',
    body: `RDV avec ${appointment.practitioner} le ${appointment.date}`,
    priority: 'high'
  });
}
```

## 🔒 Sécurité et Conformité RGPD

### Gestion des Données Sensibles
```javascript
// Toutes les données sont chiffrées et anonymisées
const secureStorage = {
  // Chiffrement des données médicales
  encrypt: async (data) => {
    return await kms.encrypt(data, {
      keyId: 'projects/bulleoapp/keys/medical-data'
    });
  },
  
  // Anonymisation pour les analyses
  anonymize: (userData) => {
    const anonymized = { ...userData };
    delete anonymized.name;
    delete anonymized.email;
    anonymized.id = hashUserId(userData.id);
    return anonymized;
  },
  
  // Suppression conforme RGPD
  deleteUserData: async (userId) => {
    await firestore.recursiveDelete(`users/${userId}`);
    await storage.deleteFolder(`users/${userId}`);
    await auditLog.record('user_data_deleted', userId);
  }
};
```

---

## 🚀 Pour Commencer

1. **Installation rapide** :
```bash
curl -sSL https://raw.githubusercontent.com/yannabadie/bulleoapp-mcp-config/main/setup.sh | bash
```

2. **Test de connexion** :
```bash
cd ~/bulleoapp-mcp/google-cloud-mcp
npx @modelcontextprotocol/inspector node dist/index.js
```

3. **Redémarrer Claude Desktop** et commencer à utiliser les commandes !

## 📞 Support

Des questions ? Contactez-nous :
- 📧 tech@bulleoapp.com
- 📚 [Documentation complète](https://docs.bulleoapp.com/mcp)
- 🐛 [Signaler un bug](https://github.com/yannabadie/bulleoapp-mcp-config/issues)