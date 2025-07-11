# 📚 JARVYS_AI - Documentation Complète

## 🚀 Installation et Configuration

### Prérequis
- **Python**: 3.11 ou supérieur
- **Docker**: 20.10+ avec support WSL2 (Windows)
- **Git**: Pour clonage et synchronisation
- **Clés API**: OpenAI, Anthropic, Gemini (optionnel)

### Installation Locale

#### 1. Cloner le Repository
```bash
git clone https://github.com/yannabadie/appIA.git
cd appIA
```

#### 2. Configuration Environnement
```bash
# Copier le template
cp .env.template .env

# Éditer les variables
nano .env
```

Variables requises:
```bash
# APIs IA (au moins une requise)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...

# Supabase (pour dashboard)
SUPABASE_URL=https://...supabase.co
SUPABASE_KEY=eyJ...

# GitHub (pour sync JARVYS_DEV)
GH_TOKEN=ghp_...
JARVYS_DEV_REPO=yannabadie/appia-dev
```

#### 3. Installation Dépendances
```bash
# Installation complète
pip install -r requirements.txt

# Installation minimale (sans audio/vision)
pip install openai anthropic python-dotenv requests
```

#### 4. Premier Lancement
```bash
# Test d'import
python test_jarvys_ai_complete.py

# Lancement JARVYS_AI
python src/jarvys_ai/main.py --mode=autonomous
```

### Installation Docker (Windows 11)

#### 1. Prérequis Windows
```powershell
# Activer WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Installer Docker Desktop
# https://docs.docker.com/desktop/windows/install/
```

#### 2. Configuration Audio (Optionnel)
```bash
# Dans WSL2 - Support audio pour Voice Interface
sudo apt update
sudo apt install pulseaudio alsa-utils
```

#### 3. Build et Lancement
```bash
# Build image
docker build -f Dockerfile.jarvys_ai -t jarvys-ai:latest .

# Lancement avec docker-compose
docker-compose -f docker-compose.windows.yml up -d

# Vérification
docker logs jarvys_ai_local
```

## 🎯 Utilisation

### Mode Autonome
```bash
# Lancement standard
python src/jarvys_ai/main.py --mode=autonomous

# Avec options
python src/jarvys_ai/main.py \
  --mode=autonomous \
  --enable-voice \
  --enable-email \
  --debug
```

### Mode Interactif
```bash
# Interface command line
python src/jarvys_ai/main.py --mode=interactive

# Commandes disponibles
jarvys > help
jarvys > status
jarvys > process email
jarvys > list tasks
jarvys > quit
```

### Mode Tâche Manuelle
```bash
# Traiter une tâche spécifique
python src/jarvys_ai/main.py \
  --mode=manual_task \
  --task="Analyser les emails et répondre aux urgents" \
  --priority=high
```

### Health Check
```bash
# Vérification santé système
python src/jarvys_ai/main.py --health-check

# Via Docker
docker exec jarvys_ai_local python src/jarvys_ai/main.py --health-check
```

## 🔌 Extensions

### Email Manager

#### Configuration
```python
config = {
    'email_accounts': [
        {
            'type': 'outlook',
            'email': 'user@company.com',
            'server': 'outlook.office365.com',
            'auth_method': 'oauth2'
        },
        {
            'type': 'gmail',
            'email': 'user@gmail.com',
            'credentials_file': 'gmail_credentials.json'
        }
    ],
    'auto_reply': True,
    'classification_enabled': True
}
```

#### Utilisation
```python
from jarvys_ai.extensions.email_manager import EmailManager

email_mgr = EmailManager(config)
await email_mgr.initialize()

# Lire nouveaux emails
emails = await email_mgr.get_new_emails()

# Répondre automatiquement
await email_mgr.auto_reply_to_email(email_id, context)
```

### Voice Interface

#### Configuration
```python
config = {
    'wake_word': 'hey jarvys',
    'language': 'fr-FR',
    'voice_speed': 1.0,
    'continuous_listening': True
}
```

#### Utilisation
```python
from jarvys_ai.extensions.voice_interface import VoiceInterface

voice = VoiceInterface(config)
await voice.initialize()

# Démarrer écoute
await voice.start_listening()

# Synthèse vocale
await voice.speak("Bonjour, je suis JARVYS_AI")
```

### Cloud Manager

#### Configuration
```python
config = {
    'gcp_project_id': 'your-project',
    'gcp_region': 'us-central1',
    'service_name': 'jarvys-ai',
    'auto_scaling': True,
    'max_instances': 5
}
```

#### Utilisation
```python
from jarvys_ai.extensions.cloud_manager import CloudManager

cloud = CloudManager(config)
await cloud.initialize()

# Déployer sur Cloud Run
deployment = await cloud.deploy_to_cloud_run()
```

### File Manager

#### Configuration
```python
config = {
    'local_storage': '/data/jarvys',
    'cloud_storage': 'gs://jarvys-bucket',
    'auto_sync': True,
    'backup_enabled': True
}
```

## 🔗 Intégrations

### Dashboard Supabase

#### Connexion
```python
from jarvys_ai.dashboard_integration import SupabaseDashboardIntegration

dashboard = SupabaseDashboardIntegration(jarvys_instance, config)
await dashboard.connect()

# Envoyer métriques
metrics = {
    'cpu_usage': 45.2,
    'memory_usage': 2048,
    'tasks_completed': 15
}
await dashboard.send_metrics(metrics)
```

#### Dashboard URL
- **Production**: https://kzcswopokvknxmxczilu.supabase.co/functions/v1/jarvys-dashboard
- **API**: https://kzcswopokvknxmxczilu.supabase.co/functions/v1/jarvys-dashboard/api

### GitHub Actions

#### Workflow Manuel
```bash
# Via GitHub CLI
gh workflow run "🤖 JARVYS_AI - Agent Local Autonome" \
  --field task="Analyser le repository et créer un rapport" \
  --field priority="medium"
```

#### Issue Processing
Les issues avec le label `from_jarvys_dev` sont automatiquement traitées:
1. Analyse du contenu
2. Exécution de la tâche
3. Commentaire avec résultats
4. Fermeture automatique

## 🛠️ Développement

### Structure du Code
```
src/jarvys_ai/
├── __init__.py              # Point d'entrée principal
├── main.py                  # Orchestrateur principal
├── intelligence_core.py     # Cœur d'intelligence
├── digital_twin.py          # Jumeau numérique
├── continuous_improvement.py # Auto-amélioration
├── fallback_engine.py       # Gestion des défaillances
├── enhanced_fallback_engine.py # Fallback avancé
├── dashboard_integration.py # Intégration dashboard
└── extensions/
    ├── __init__.py
    ├── email_manager.py     # Gestion emails
    ├── voice_interface.py   # Interface vocale
    ├── cloud_manager.py     # Gestion cloud
    └── file_manager.py      # Gestion fichiers
```

### Tests
```bash
# Tests complets
python test_jarvys_ai_complete.py

# Test module spécifique
python -c "
import sys; sys.path.append('src')
from jarvys_ai.intelligence_core import IntelligenceCore
core = IntelligenceCore({'demo_mode': True})
print('✅ Intelligence Core OK')
"
```

### Debug
```bash
# Mode debug avec logs détaillés
export JARVYS_DEBUG=true
python src/jarvys_ai/main.py --mode=autonomous --debug

# Logs en temps réel
tail -f logs/jarvys_ai.log
```

## 🔧 Configuration Avancée

### Personnalisation Intelligence Core
```python
config = {
    'ai_models': {
        'primary': 'gpt-4',
        'secondary': 'claude-3-sonnet',
        'fallback': 'gpt-3.5-turbo'
    },
    'response_style': 'professional',
    'language_preference': 'fr',
    'context_memory': True
}
```

### Optimisation Performance
```python
config = {
    'cache_enabled': True,
    'cache_ttl': 3600,
    'batch_processing': True,
    'parallel_tasks': 4,
    'rate_limiting': {
        'openai': 60,  # requests per minute
        'anthropic': 30
    }
}
```

## 📊 Monitoring

### Métriques Disponibles
- **Performance**: Temps de réponse, throughput
- **Ressources**: CPU, mémoire, disque
- **API**: Quotas, erreurs, latence
- **Business**: Tâches traitées, satisfaction

### Alerting
```python
config = {
    'alerts': {
        'high_cpu': {'threshold': 80, 'action': 'scale_up'},
        'quota_exceeded': {'action': 'switch_to_fallback'},
        'error_rate': {'threshold': 5, 'action': 'notify_admin'}
    }
}
```

## 🔍 Troubleshooting

### Problèmes Courants

#### ImportError: No module named 'openai'
```bash
pip install openai anthropic python-dotenv
```

#### Docker: Permission denied
```bash
sudo chmod +x docker-entrypoint.sh
docker-compose down && docker-compose up --build
```

#### Voice Interface: No audio device
```bash
# Linux/WSL2
sudo apt install pulseaudio alsa-utils
pulseaudio --start

# Windows - Vérifier Windows Speech API
```

#### GitHub Actions: Quota exceeded
Le système bascule automatiquement vers Cloud Run:
1. Monitoring quota en temps réel
2. Déploiement Cloud Run automatique
3. Retour GitHub Actions quand quota disponible

### Logs Debug
```bash
# Activer logs détaillés
export JARVYS_LOG_LEVEL=DEBUG

# Fichiers de logs
tail -f logs/jarvys_ai.log
tail -f logs/intelligence_core.log
tail -f logs/extensions.log
```

## 🚀 Déploiement Production

### Configuration Production
```bash
export JARVYS_MODE=production
export JARVYS_AGENT_TYPE=local
export JARVYS_AUTO_IMPROVE=true
export JARVYS_MONITORING=true
```

### Scaling
```bash
# Docker Swarm
docker swarm init
docker service create --name jarvys-ai --replicas 3 jarvys-ai:latest

# Kubernetes
kubectl apply -f k8s/jarvys-ai-deployment.yaml
```

### Backup
```bash
# Automatique via File Manager
config = {
    'backup_schedule': '0 2 * * *',  # Daily at 2 AM
    'backup_retention': 30,  # 30 days
    'backup_location': 'gs://jarvys-backups'
}
```

## 📞 Support

### Logs et Diagnostics
```bash
# Health check complet
python src/jarvys_ai/main.py --health-check --verbose

# Export diagnostics
python src/jarvys_ai/main.py --export-diagnostics
```

### Contact
- **Issues**: GitHub Issues dans repository
- **Dashboard**: Monitoring via Supabase dashboard
- **Logs**: Centralisés dans `/logs/`