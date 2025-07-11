#!/usr/bin/env python3
"""
🔄 JARVYS_AI - Script de Synchronisation
Synchronisation entre JARVYS_AI (appIA) et JARVYS_DEV (appia-dev)
"""

import asyncio
import json
import logging
import os
import requests
import sys
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path

# Configuration logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - SYNC - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class JarvysAISync:
    """
    🔄 Gestionnaire de synchronisation JARVYS_AI
    
    Fonctionnalités:
    - Sync status avec JARVYS_DEV
    - Mise à jour configuration
    - Partage de métriques
    - Synchronisation mémoire
    """
    
    def __init__(self):
        """Initialiser le gestionnaire de sync"""
        self.config = self._load_config()
        self.session = requests.Session()
        
        # Configuration sync
        self.supabase_url = os.getenv('SUPABASE_URL')
        self.supabase_key = os.getenv('SUPABASE_KEY')
        self.github_token = os.getenv('GH_TOKEN')
        self.jarvys_dev_repo = os.getenv('JARVYS_DEV_REPO', 'yannabadie/appia-dev')
        
        # Headers pour requêtes
        self.supabase_headers = {
            'apikey': self.supabase_key,
            'Authorization': f'Bearer {self.supabase_key}',
            'Content-Type': 'application/json'
        }
        
        self.github_headers = {
            'Authorization': f'token {self.github_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        logger.info("🔄 JARVYS_AI Sync initialisé")
    
    def _load_config(self) -> Dict[str, Any]:
        """Charger la configuration"""
        config_path = Path(__file__).parent / "config" / "jarvys_ai_config.json"
        
        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        
        # Configuration par défaut
        return {
            "jarvys_ai": {
                "version": "1.0.0",
                "agent_type": "local",
                "created_date": datetime.now().isoformat(),
                "capabilities": [
                    "code_analysis",
                    "repository_management", 
                    "local_execution",
                    "file_operations",
                    "git_operations",
                    "issue_handling",
                    "continuous_improvement",
                    "dashboard_integration"
                ]
            }
        }
    
    async def update_agent_status(self) -> bool:
        """Mettre à jour le statut de l'agent dans Supabase"""
        try:
            status_data = {
                'agent_id': 'jarvys_ai_local',
                'agent_type': 'local',
                'status': 'active',
                'last_seen': datetime.now().isoformat(),
                'version': self.config.get('jarvys_ai', {}).get('version', '1.0.0'),
                'capabilities': self.config.get('jarvys_ai', {}).get('capabilities', []),
                'location': 'github_actions',
                'repository': 'yannabadie/appIA',
                'health_score': await self._calculate_health_score(),
                'metadata': {
                    'python_version': f"{sys.version_info.major}.{sys.version_info.minor}",
                    'platform': sys.platform,
                    'sync_script_version': '1.0.0'
                }
            }
            
            # Envoyer à Supabase
            response = self.session.post(
                f"{self.supabase_url}/rest/v1/jarvys_agents_status",
                headers=self.supabase_headers,
                json=status_data
            )
            
            if response.status_code in [200, 201]:
                logger.info("✅ Statut agent mis à jour dans Supabase")
                return True
            else:
                logger.error(f"❌ Erreur mise à jour statut: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Erreur update_agent_status: {e}")
            return False
    
    async def send_metrics(self, metrics: Optional[Dict[str, Any]] = None) -> bool:
        """Envoyer métriques au dashboard"""
        try:
            if metrics is None:
                metrics = await self._collect_metrics()
            
            metrics_data = {
                'agent_id': 'jarvys_ai_local',
                'timestamp': datetime.now().isoformat(),
                'metrics': metrics,
                'source': 'sync_script'
            }
            
            # Envoyer à Supabase
            response = self.session.post(
                f"{self.supabase_url}/rest/v1/jarvys_metrics",
                headers=self.supabase_headers,
                json=metrics_data
            )
            
            if response.status_code in [200, 201]:
                logger.info("📊 Métriques envoyées au dashboard")
                return True
            else:
                logger.error(f"❌ Erreur envoi métriques: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Erreur send_metrics: {e}")
            return False
    
    async def sync_with_jarvys_dev(self) -> bool:
        """Synchroniser avec JARVYS_DEV"""
        try:
            # Obtenir les informations du repo JARVYS_DEV
            response = self.session.get(
                f"https://api.github.com/repos/{self.jarvys_dev_repo}",
                headers=self.github_headers
            )
            
            if response.status_code != 200:
                logger.error(f"❌ Impossible d'accéder à JARVYS_DEV: {response.status_code}")
                return False
            
            repo_info = response.json()
            
            # Obtenir les derniers commits
            commits_response = self.session.get(
                f"https://api.github.com/repos/{self.jarvys_dev_repo}/commits",
                headers=self.github_headers,
                params={'per_page': 5}
            )
            
            if commits_response.status_code == 200:
                commits = commits_response.json()
                latest_commit = commits[0] if commits else None
                
                sync_data = {
                    'sync_timestamp': datetime.now().isoformat(),
                    'jarvys_dev_status': 'active',
                    'latest_commit': {
                        'sha': latest_commit['sha'][:7] if latest_commit else None,
                        'message': latest_commit['commit']['message'][:100] if latest_commit else None,
                        'date': latest_commit['commit']['committer']['date'] if latest_commit else None
                    },
                    'repo_stats': {
                        'stars': repo_info.get('stargazers_count', 0),
                        'forks': repo_info.get('forks_count', 0),
                        'open_issues': repo_info.get('open_issues_count', 0),
                        'size': repo_info.get('size', 0)
                    }
                }
                
                # Envoyer les données de sync
                response = self.session.post(
                    f"{self.supabase_url}/rest/v1/jarvys_sync_data",
                    headers=self.supabase_headers,
                    json=sync_data
                )
                
                if response.status_code in [200, 201]:
                    logger.info("🔄 Sync avec JARVYS_DEV réussie")
                    return True
                else:
                    logger.error(f"❌ Erreur sync JARVYS_DEV: {response.status_code}")
                    return False
            
        except Exception as e:
            logger.error(f"❌ Erreur sync_with_jarvys_dev: {e}")
            return False
    
    async def check_for_updates(self) -> Dict[str, Any]:
        """Vérifier s'il y a des mises à jour disponibles"""
        try:
            # Vérifier les dernières releases
            response = self.session.get(
                f"https://api.github.com/repos/{self.jarvys_dev_repo}/releases/latest",
                headers=self.github_headers
            )
            
            updates_info = {
                'updates_available': False,
                'latest_version': None,
                'current_version': self.config.get('jarvys_ai', {}).get('version', '1.0.0'),
                'release_notes': None
            }
            
            if response.status_code == 200:
                release = response.json()
                latest_version = release.get('tag_name', '').replace('v', '')
                current_version = updates_info['current_version']
                
                # Comparaison simple de version
                if latest_version and latest_version != current_version:
                    updates_info.update({
                        'updates_available': True,
                        'latest_version': latest_version,
                        'release_notes': release.get('body', '')[:500],
                        'release_url': release.get('html_url'),
                        'published_at': release.get('published_at')
                    })
                    
                    logger.info(f"🆕 Mise à jour disponible: {latest_version}")
                else:
                    logger.info("✅ JARVYS_AI à jour")
            
            return updates_info
            
        except Exception as e:
            logger.error(f"❌ Erreur check_for_updates: {e}")
            return {'error': str(e)}
    
    async def _calculate_health_score(self) -> float:
        """Calculer un score de santé de l'agent"""
        try:
            score = 100.0
            
            # Vérifier les dépendances critiques
            try:
                import sys
                sys.path.append('src')
                from jarvys_ai import JarvysAI
                score += 0  # Import OK
            except Exception:
                score -= 20  # Import failed
            
            # Vérifier la configuration
            if not self.supabase_url or not self.supabase_key:
                score -= 10
            
            if not self.github_token:
                score -= 5
            
            # Vérifier la connectivité
            try:
                response = self.session.get(f"{self.supabase_url}/rest/v1/", 
                                          headers=self.supabase_headers, 
                                          timeout=5)
                if response.status_code != 200:
                    score -= 15
            except Exception:
                score -= 20
            
            return max(0.0, min(100.0, score))
            
        except Exception as e:
            logger.error(f"❌ Erreur calcul health score: {e}")
            return 50.0  # Score neutre en cas d'erreur
    
    async def _collect_metrics(self) -> Dict[str, Any]:
        """Collecter métriques système"""
        try:
            import psutil
            
            metrics = {
                'cpu_percent': psutil.cpu_percent(interval=1),
                'memory_percent': psutil.virtual_memory().percent,
                'disk_percent': psutil.disk_usage('/').percent,
                'process_count': len(psutil.pids()),
                'uptime_seconds': (datetime.now() - datetime.fromtimestamp(psutil.boot_time())).total_seconds()
            }
            
        except ImportError:
            # Métriques basiques si psutil n'est pas disponible
            metrics = {
                'python_version': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
                'platform': sys.platform,
                'timestamp': datetime.now().isoformat()
            }
        
        return metrics
    
    async def run_full_sync(self) -> Dict[str, bool]:
        """Exécuter une synchronisation complète"""
        logger.info("🚀 Début synchronisation complète JARVYS_AI")
        
        results = {
            'agent_status': await self.update_agent_status(),
            'metrics': await self.send_metrics(),
            'jarvys_dev_sync': await self.sync_with_jarvys_dev()
        }
        
        # Vérifier les mises à jour
        updates = await self.check_for_updates()
        results['updates_checked'] = 'error' not in updates
        
        success_count = sum(1 for success in results.values() if success)
        total_count = len(results)
        
        logger.info(f"✅ Synchronisation terminée: {success_count}/{total_count} réussies")
        
        return results

async def main():
    """Point d'entrée principal"""
    try:
        sync_manager = JarvysAISync()
        results = await sync_manager.run_full_sync()
        
        # Code de sortie basé sur les résultats
        if all(results.values()):
            logger.info("🎉 Synchronisation 100% réussie")
            return 0
        else:
            failed = [k for k, v in results.items() if not v]
            logger.warning(f"⚠️ Échecs: {', '.join(failed)}")
            return 1
            
    except Exception as e:
        logger.error(f"❌ Erreur critique synchronisation: {e}")
        return 2

if __name__ == "__main__":
    exit(asyncio.run(main()))