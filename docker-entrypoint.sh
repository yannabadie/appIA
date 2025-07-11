#!/bin/bash
# 🤖 JARVYS_AI Docker Entrypoint Script

set -e

echo "🤖 Démarrage de JARVYS_AI..."
echo "📅 $(date)"
echo "🏷️  Version: 1.0.0"
echo "🏠 Mode: $JARVYS_MODE"

# Vérifier les variables d'environnement essentielles
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️ OPENAI_API_KEY non définie - certaines fonctionnalités seront limitées"
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo "⚠️ Configuration Supabase manquante - mode local uniquement"
fi

# Créer les répertoires nécessaires
mkdir -p /app/logs /app/data ~/.jarvys_ai/cache

# Initialiser la configuration
echo "⚙️ Initialisation de la configuration..."
if [ ! -f "/app/config/jarvys_ai_config.json" ]; then
    echo "❌ Configuration manquante!"
    exit 1
fi

# Test des dépendances critiques
echo "🔍 Vérification des dépendances..."
python -c "import openai, anthropic; print('✅ Dépendances IA disponibles')" || echo "⚠️ Certaines dépendances IA manquantes"

# Démarrer JARVYS_AI avec les arguments fournis
echo "🚀 Lancement de JARVYS_AI..."
cd /app
exec python src/jarvys_ai/main.py "$@"