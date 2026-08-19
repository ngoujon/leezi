# Leezi

Lecteur de texte pour macOS : glisse-dépose ou colle un texte, écoute-le en voix homme/femme,
avec play/pause, avance/recul de 10 secondes, réglage de la vitesse, et nettoyage du texte
via Ollama Cloud.

## Configuration de la clé API Ollama Cloud

1. Copie `Config/Secrets.swift.example` vers `Sources/Leezi/Secrets.swift`.
2. Remplace `COLLE_TA_CLE_ICI` par ta clé API Ollama Cloud (https://ollama.com/settings/keys).

Ce fichier `Sources/Leezi/Secrets.swift` est ignoré par git (voir `.gitignore`) pour ne jamais
committer la clé.

## Lancer en développement

```bash
swift run
```

## Générer l'application macOS (Leezi.app)

```bash
./build_app.sh
open Leezi.app
```

## Notes

- La synthèse vocale utilise les voix système macOS (AVSpeechSynthesizer) ; le choix
  homme/femme filtre les voix françaises installées. Pour plus de voix, ajoute-en dans
  Réglages Système > Accessibilité > Contenu énoncé.
- Le modèle Ollama Cloud utilisé par défaut est `gpt-oss:20b-cloud` (modifiable dans
  `Sources/Leezi/OllamaClient.swift`).
