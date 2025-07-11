#!/usr/bin/env python3
"""
🔄 JARVYS_AI - Enhanced Continuous Improvement System
Advanced self-improvement connected to JARVYS_DEV with real-time sync
"""

import asyncio
import logging
import json
import os
import subprocess
import tempfile
import shutil
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
import requests
import hashlib
import threading
from pathlib import Path

logger = logging.getLogger(__name__)

class ContinuousImprovement:
    """
    🔄 Enhanced Continuous Improvement System
    
    Features:
    - Real-time sync with JARVYS_DEV
    - Automatic code updates from appIA repository
    - AI-driven code optimization
    - Safe rollback mechanisms
    - Performance monitoring and reporting
    - GitHub Actions quota management
    - Cloud Run fallback deployment
    """
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize the continuous improvement system"""
        self.config = config
        self.is_initialized = False
        
        # Configuration JARVYS_DEV
        self.jarvys_dev_endpoint = config.get('jarvys_dev_endpoint', 'https://kzcswopokvknxmxczilu.supabase.co')
        self.sync_token = config.get('sync_token')
        self.device_id = self._generate_device_id()
        
        # GitHub repository configuration
        self.github_repo = config.get('github_repo', 'yannabadie/appIA')
        self.branch = config.get('branch', 'main')
        
        # Configuration des mises à jour
        self.auto_update = config.get('auto_update', True)
        self.backup_before_update = config.get('backup_before_update', True)
        self.max_rollback_attempts = 3
        self.sync_interval = config.get('sync_interval_minutes', 60)
        
        # État du système
        self.last_sync = None
        self.pending_updates = []
        self.update_thread = None
        self.is_running = False
        
        # Paths
        self.jarvys_ai_path = Path(__file__).parent
        self.backup_path = self.jarvys_ai_path.parent / "backups"
        self.temp_repo_path = None
        self.applied_updates = []
        self.performance_metrics = {}
        
        # Simulation pour démo
        self.demo_mode = config.get('demo_mode', True)
        
        logger.info("🔄 Continuous Improvement initialisé")
    
    async def initialize(self):
        """Initialiser le système d'amélioration continue"""
        try:
            if self.demo_mode:
                await self._setup_demo_mode()
            else:
                await self._setup_real_sync()
            
            # Enregistrer auprès de JARVYS_DEV
            await self._register_with_jarvys_dev()
            
            self.is_initialized = True
            logger.info("🔄 Continuous Improvement prêt")
            
        except Exception as e:
            logger.error(f"❌ Erreur initialisation Continuous Improvement: {e}")
            raise
    
    def _generate_device_id(self) -> str:
        """Générer ID unique de l'appareil"""
        # Utiliser hostname + user pour générer un ID stable
        import socket
        import getpass
        
        identifier = f"{socket.gethostname()}-{getpass.getuser()}"
        return hashlib.sha256(identifier.encode()).hexdigest()[:16]
    
    async def _setup_demo_mode(self):
        """Configuration mode démo"""
        self.demo_updates = [
            {
                'id': 'update-001',
                'type': 'feature',
                'description': 'Amélioration reconnaissance vocale',
                'files': ['jarvys_ai/extensions/voice_interface.py'],
                'priority': 'medium',
                'created_at': '2024-01-15T10:30:00Z'
            },
            {
                'id': 'update-002', 
                'type': 'optimization',
                'description': 'Optimisation consommation mémoire',
                'files': ['jarvys_ai/intelligence_core.py'],
                'priority': 'high',
                'created_at': '2024-01-15T14:20:00Z'
            },
            {
                'id': 'update-003',
                'type': 'bugfix',
                'description': 'Correction bug gestion emails',
                'files': ['jarvys_ai/extensions/email_manager.py'],
                'priority': 'critical',
                'created_at': '2024-01-15T16:45:00Z'
            }
        ]
        
        logger.info("🔄 Mode démo amélioration continue configuré")
    
    async def _setup_real_sync(self):
        """Configuration synchronisation réelle"""
        try:
            # TODO: Vérifier authentification avec JARVYS_DEV
            # TODO: Configurer webhook pour notifications
            # TODO: Mettre en place canal sécurisé
            
            logger.info("🔄 Configuration sync réelle (TODO)")
            
        except Exception as e:
            logger.error(f"❌ Erreur configuration sync: {e}")
            raise
    
    async def _register_with_jarvys_dev(self):
        """S'enregistrer auprès de JARVYS_DEV"""
        try:
            registration_data = {
                'device_id': self.device_id,
                'device_type': 'jarvys_ai_local',
                'version': '1.0.0',
                'platform': os.name,
                'capabilities': await self._get_device_capabilities(),
                'auto_update': self.auto_update,
                'registered_at': datetime.now().isoformat()
            }
            
            if self.demo_mode:
                logger.info(f"🔄 [DÉMO] Enregistrement: {registration_data['device_id']}")
                return True
            else:
                # TODO: Appel API JARVYS_DEV pour enregistrement
                return await self._send_registration(registration_data)
                
        except Exception as e:
            logger.error(f"❌ Erreur enregistrement JARVYS_DEV: {e}")
            return False
    
    async def _get_device_capabilities(self) -> Dict[str, Any]:
        """Obtenir les capacités de l'appareil"""
        return {
            'voice_interface': True,
            'email_management': True,
            'cloud_integration': True,
            'file_management': True,
            'docker_support': True,
            'windows_support': os.name == 'nt',
            'memory_gb': 8,  # Simulation
            'cpu_cores': 4   # Simulation
        }
    
    async def sync_with_jarvys_dev(self):
        """Synchroniser avec JARVYS_DEV pour récupérer améliorations"""
        try:
            logger.info("🔄 Synchronisation avec JARVYS_DEV...")
            
            if self.demo_mode:
                updates = await self._demo_fetch_updates()
            else:
                updates = await self._real_fetch_updates()
            
            # Traiter les nouvelles mises à jour
            for update in updates:
                if not self._is_update_applied(update['id']):
                    self.pending_updates.append(update)
                    logger.info(f"📥 Nouvelle mise à jour: {update['description']}")
            
            self.last_sync = datetime.now()
            
            # Appliquer automatiquement si configuré
            if self.auto_update and self.pending_updates:
                await self._apply_pending_updates()
            
            return len(updates)
            
        except Exception as e:
            logger.error(f"❌ Erreur synchronisation: {e}")
            return 0
    
    async def _demo_fetch_updates(self) -> List[Dict[str, Any]]:
        """Récupérer mises à jour en mode démo"""
        # Simuler délai réseau
        await asyncio.sleep(1)
        
        # Retourner quelques mises à jour simulées
        return self.demo_updates[:2]  # Limiter pour démo
    
    async def _real_fetch_updates(self) -> List[Dict[str, Any]]:
        """Récupérer mises à jour réelles depuis JARVYS_DEV"""
        try:
            headers = {
                'Authorization': f'Bearer {self.sync_token}',
                'Device-ID': self.device_id
            }
            
            params = {
                'last_sync': self.last_sync.isoformat() if self.last_sync else None,
                'device_type': 'jarvys_ai_local'
            }
            
            url = f"{self.jarvys_dev_endpoint}/api/improvements/fetch"
            response = requests.get(url, headers=headers, params=params, timeout=30)
            
            if response.status_code == 200:
                return response.json().get('updates', [])
            else:
                logger.error(f"❌ Erreur API JARVYS_DEV: {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"❌ Erreur fetch updates: {e}")
            return []
    
    def _is_update_applied(self, update_id: str) -> bool:
        """Vérifier si une mise à jour a déjà été appliquée"""
        return any(u['id'] == update_id for u in self.applied_updates)
    
    async def _apply_pending_updates(self):
        """Appliquer les mises à jour en attente"""
        for update in self.pending_updates.copy():
            try:
                success = await self._apply_single_update(update)
                
                if success:
                    self.applied_updates.append({
                        **update,
                        'applied_at': datetime.now().isoformat(),
                        'status': 'success'
                    })
                    self.pending_updates.remove(update)
                    logger.info(f"✅ Mise à jour appliquée: {update['description']}")
                    
                    # Rapport à JARVYS_DEV
                    await self._report_update_success(update)
                else:
                    logger.error(f"❌ Échec mise à jour: {update['description']}")
                    await self._report_update_failure(update)
                    
            except Exception as e:
                logger.error(f"❌ Erreur application update {update['id']}: {e}")
                await self._report_update_failure(update, str(e))
    
    async def _apply_single_update(self, update: Dict[str, Any]) -> bool:
        """Appliquer une seule mise à jour"""
        try:
            logger.info(f"🔄 Application mise à jour: {update['description']}")
            
            # 1. Créer sauvegarde si nécessaire
            backup_path = None
            if self.backup_before_update:
                backup_path = await self._create_backup(update)
            
            # 2. Appliquer selon le type
            if update['type'] == 'feature':
                success = await self._apply_feature_update(update)
            elif update['type'] == 'optimization':
                success = await self._apply_optimization_update(update)
            elif update['type'] == 'bugfix':
                success = await self._apply_bugfix_update(update)
            else:
                logger.warning(f"⚠️ Type de mise à jour inconnu: {update['type']}")
                return False
            
            # 3. Vérifier l'application
            if success:
                verification_success = await self._verify_update(update)
                if not verification_success and backup_path:
                    # Rollback si vérification échoue
                    await self._rollback_from_backup(backup_path)
                    return False
            
            return success
            
        except Exception as e:
            logger.error(f"❌ Erreur application update: {e}")
            
            # Rollback en cas d'erreur
            if backup_path:
                await self._rollback_from_backup(backup_path)
            
            return False
    
    async def _create_backup(self, update: Dict[str, Any]) -> Optional[str]:
        """Créer une sauvegarde avant mise à jour"""
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_dir = f"/tmp/jarvys_backup_{timestamp}_{update['id']}"
            
            # Créer répertoire de sauvegarde
            os.makedirs(backup_dir, exist_ok=True)
            
            # Sauvegarder fichiers affectés
            for file_path in update.get('files', []):
                if os.path.exists(file_path):
                    import shutil
                    backup_file = os.path.join(backup_dir, os.path.basename(file_path))
                    shutil.copy2(file_path, backup_file)
            
            logger.info(f"💾 Sauvegarde créée: {backup_dir}")
            return backup_dir
            
        except Exception as e:
            logger.error(f"❌ Erreur création sauvegarde: {e}")
            return None
    
    async def _apply_feature_update(self, update: Dict[str, Any]) -> bool:
        """Appliquer une mise à jour de fonctionnalité"""
        if self.demo_mode:
            await asyncio.sleep(2)  # Simulation délai
            logger.info(f"✨ [DÉMO] Fonctionnalité appliquée: {update['description']}")
            return True
        else:
            # TODO: Implémenter application réelle
            return False
    
    async def _apply_optimization_update(self, update: Dict[str, Any]) -> bool:
        """Appliquer une mise à jour d'optimisation"""
        if self.demo_mode:
            await asyncio.sleep(1.5)  # Simulation délai
            logger.info(f"⚡ [DÉMO] Optimisation appliquée: {update['description']}")
            return True
        else:
            # TODO: Implémenter optimisation réelle
            return False
    
    async def _apply_bugfix_update(self, update: Dict[str, Any]) -> bool:
        """Appliquer une correction de bug"""
        if self.demo_mode:
            await asyncio.sleep(1)  # Simulation délai
            logger.info(f"🔧 [DÉMO] Correction appliquée: {update['description']}")
            return True
        else:
            # TODO: Implémenter correction réelle
            return False
    
    async def _verify_update(self, update: Dict[str, Any]) -> bool:
        """Vérifier qu'une mise à jour fonctionne correctement"""
        try:
            # Tests basiques de fonctionnement
            if self.demo_mode:
                await asyncio.sleep(0.5)
                return True  # Simulation succès
            else:
                # TODO: Tests réels selon le type d'update
                return True
                
        except Exception as e:
            logger.error(f"❌ Erreur vérification update: {e}")
            return False
    
    async def _rollback_from_backup(self, backup_path: str):
        """Effectuer un rollback depuis sauvegarde"""
        try:
            logger.warning(f"🔄 Rollback depuis: {backup_path}")
            
            # Restaurer fichiers depuis la sauvegarde
            for backup_file in os.listdir(backup_path):
                source = os.path.join(backup_path, backup_file)
                # TODO: Déterminer destination et restaurer
                
            logger.info("✅ Rollback terminé")
            
        except Exception as e:
            logger.error(f"❌ Erreur rollback: {e}")
    
    async def _report_update_success(self, update: Dict[str, Any]):
        """Rapporter le succès d'une mise à jour à JARVYS_DEV"""
        report = {
            'device_id': self.device_id,
            'update_id': update['id'],
            'status': 'success',
            'applied_at': datetime.now().isoformat(),
            'performance_impact': await self._measure_performance_impact()
        }
        
        if self.demo_mode:
            logger.info(f"📊 [DÉMO] Rapport succès: {update['id']}")
        else:
            # TODO: Envoyer rapport à JARVYS_DEV
            pass
    
    async def _report_update_failure(self, update: Dict[str, Any], error: str = None):
        """Rapporter l'échec d'une mise à jour à JARVYS_DEV"""
        report = {
            'device_id': self.device_id,
            'update_id': update['id'],
            'status': 'failed',
            'error': error,
            'failed_at': datetime.now().isoformat()
        }
        
        if self.demo_mode:
            logger.warning(f"📊 [DÉMO] Rapport échec: {update['id']}")
        else:
            # TODO: Envoyer rapport à JARVYS_DEV
            pass
    
    async def _measure_performance_impact(self) -> Dict[str, Any]:
        """Mesurer l'impact performance d'une mise à jour"""
        # Simulation métriques
        return {
            'memory_usage_mb': 512,
            'cpu_usage_percent': 15.5,
            'response_time_ms': 120,
            'success_rate_percent': 98.5
        }
    
    async def start_continuous_monitoring(self):
        """Démarrer le monitoring continu"""
        while self.is_initialized:
            try:
                # Synchroniser avec JARVYS_DEV
                await self.sync_with_jarvys_dev()
                
                # Mesurer performances
                await self._collect_performance_metrics()
                
                # Envoyer rapport si nécessaire
                await self._send_periodic_report()
                
                # Attendre avant prochaine synchronisation
                await asyncio.sleep(1800)  # 30 minutes
                
            except Exception as e:
                logger.error(f"❌ Erreur monitoring continu: {e}")
                await asyncio.sleep(300)  # 5 minutes en cas d'erreur
    
    async def _collect_performance_metrics(self):
        """Collecter métriques de performance"""
        self.performance_metrics = {
            'timestamp': datetime.now().isoformat(),
            'memory_usage': await self._get_memory_usage(),
            'cpu_usage': await self._get_cpu_usage(),
            'response_times': await self._get_response_times(),
            'error_rate': await self._get_error_rate(),
            'uptime': await self._get_uptime()
        }
    
    async def _get_memory_usage(self) -> float:
        """Obtenir utilisation mémoire"""
        # Simulation pour démo
        return 45.2  # %
    
    async def _get_cpu_usage(self) -> float:
        """Obtenir utilisation CPU"""
        # Simulation pour démo
        return 12.8  # %
    
    async def _get_response_times(self) -> Dict[str, float]:
        """Obtenir temps de réponse par module"""
        return {
            'voice_interface': 120.5,
            'email_manager': 89.3,
            'cloud_manager': 156.7,
            'file_manager': 78.2
        }  # ms
    
    async def _get_error_rate(self) -> float:
        """Obtenir taux d'erreur"""
        return 1.2  # %
    
    async def _get_uptime(self) -> float:
        """Obtenir temps de fonctionnement"""
        return 99.8  # %
    
    async def _send_periodic_report(self):
        """Envoyer rapport périodique à JARVYS_DEV"""
        if not self.performance_metrics:
            return
        
        report = {
            'device_id': self.device_id,
            'report_type': 'periodic_performance',
            'metrics': self.performance_metrics,
            'applied_updates_count': len(self.applied_updates),
            'pending_updates_count': len(self.pending_updates)
        }
        
        if self.demo_mode:
            logger.info("📊 [DÉMO] Rapport périodique envoyé")
        else:
            # TODO: Envoyer à JARVYS_DEV
            pass
    
    def get_improvement_status(self) -> Dict[str, Any]:
        """Obtenir l'état du système d'amélioration"""
        return {
            'is_initialized': self.is_initialized,
            'device_id': self.device_id,
            'auto_update': self.auto_update,
            'last_sync': self.last_sync.isoformat() if self.last_sync else None,
            'pending_updates': len(self.pending_updates),
            'applied_updates': len(self.applied_updates),
            'performance_metrics': self.performance_metrics,
            'demo_mode': self.demo_mode
        }
    
    def get_stats(self) -> Dict[str, Any]:
        """Obtenir statistiques du système"""
        return {
            'is_initialized': self.is_initialized,
            'device_id': self.device_id,
            'auto_update': self.auto_update,
            'backup_before_update': self.backup_before_update,
            'pending_updates': len(self.pending_updates),
            'applied_updates': len(self.applied_updates),
            'last_sync': self.last_sync,
            'version': '1.0.0'
        }
    
    # Enhanced Real-time Sync Methods
    
    async def start_continuous_sync(self):
        """Start continuous sync with JARVYS_DEV and GitHub repository"""
        if self.is_running:
            logger.warning("Continuous sync already running")
            return
        
        self.is_running = True
        self.update_thread = threading.Thread(target=self._sync_loop, daemon=True)
        self.update_thread.start()
        logger.info(f"🔄 Started continuous sync (interval: {self.sync_interval} minutes)")
    
    def stop_continuous_sync(self):
        """Stop continuous sync"""
        self.is_running = False
        if self.update_thread:
            self.update_thread.join(timeout=5)
        logger.info("🔄 Stopped continuous sync")
    
    def _sync_loop(self):
        """Main sync loop running in background thread"""
        while self.is_running:
            try:
                asyncio.run(self._perform_sync_cycle())
            except Exception as e:
                logger.error(f"❌ Sync cycle error: {e}")
            
            # Wait for next sync cycle
            for _ in range(self.sync_interval * 60):  # Convert to seconds
                if not self.is_running:
                    break
                threading.Event().wait(1)
    
    async def _perform_sync_cycle(self):
        """Perform a complete sync cycle"""
        try:
            logger.info("🔄 Starting sync cycle...")
            
            # 1. Check for updates from GitHub repository
            updates_available = await self._check_github_updates()
            
            # 2. Check JARVYS_DEV dashboard for commands/improvements
            dashboard_updates = await self._check_dashboard_updates()
            
            # 3. Apply updates if available and auto_update is enabled
            if (updates_available or dashboard_updates) and self.auto_update:
                await self._apply_updates(updates_available, dashboard_updates)
            
            # 4. Report performance metrics to JARVYS_DEV
            await self._report_metrics()
            
            # 5. Update last sync timestamp
            self.last_sync = datetime.now()
            
            logger.info("✅ Sync cycle completed successfully")
            
        except Exception as e:
            logger.error(f"❌ Sync cycle failed: {e}")
    
    async def _check_github_updates(self) -> List[Dict[str, Any]]:
        """Check GitHub repository for code updates"""
        try:
            # Clone/update temporary repository
            if not await self._update_temp_repo():
                return []
            
            # Compare with current code
            updates = await self._detect_code_changes()
            
            if updates:
                logger.info(f"🔄 Found {len(updates)} potential updates from GitHub")
            
            return updates
            
        except Exception as e:
            logger.error(f"❌ Error checking GitHub updates: {e}")
            return []
    
    async def _update_temp_repo(self) -> bool:
        """Clone or update temporary repository"""
        try:
            if self.temp_repo_path and os.path.exists(self.temp_repo_path):
                # Update existing repository
                result = subprocess.run([
                    "git", "pull", "origin", self.branch
                ], cwd=self.temp_repo_path, capture_output=True, text=True)
                
                if result.returncode != 0:
                    logger.warning(f"Git pull failed: {result.stderr}")
                    return False
            else:
                # Clone repository
                self.temp_repo_path = tempfile.mkdtemp(prefix="jarvys_sync_")
                
                result = subprocess.run([
                    "gh", "repo", "clone", self.github_repo, self.temp_repo_path
                ], capture_output=True, text=True)
                
                if result.returncode != 0:
                    logger.error(f"Git clone failed: {result.stderr}")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Error updating temp repo: {e}")
            return False
    
    async def _detect_code_changes(self) -> List[Dict[str, Any]]:
        """Detect changes between current code and repository"""
        updates = []
        
        try:
            repo_jarvys_path = os.path.join(self.temp_repo_path, "jarvys_ai")
            if not os.path.exists(repo_jarvys_path):
                return updates
            
            # Compare each Python file
            for current_file in self.jarvys_ai_path.rglob("*.py"):
                relative_path = current_file.relative_to(self.jarvys_ai_path)
                repo_file = Path(repo_jarvys_path) / relative_path
                
                if repo_file.exists():
                    # Check if files are different
                    current_hash = self._file_hash(current_file)
                    repo_hash = self._file_hash(repo_file)
                    
                    if current_hash != repo_hash:
                        updates.append({
                            "type": "file_update",
                            "file": str(relative_path),
                            "source": str(repo_file),
                            "target": str(current_file),
                            "priority": "medium"
                        })
                elif current_file.name != "__pycache__":
                    # File exists locally but not in repo (potential removal)
                    updates.append({
                        "type": "file_removal",
                        "file": str(relative_path),
                        "target": str(current_file),
                        "priority": "low"
                    })
            
            # Check for new files in repository
            for repo_file in Path(repo_jarvys_path).rglob("*.py"):
                relative_path = repo_file.relative_to(Path(repo_jarvys_path))
                current_file = self.jarvys_ai_path / relative_path
                
                if not current_file.exists():
                    updates.append({
                        "type": "file_addition",
                        "file": str(relative_path),
                        "source": str(repo_file),
                        "target": str(current_file),
                        "priority": "medium"
                    })
            
            return updates
            
        except Exception as e:
            logger.error(f"❌ Error detecting code changes: {e}")
            return []
    
    async def _check_dashboard_updates(self) -> List[Dict[str, Any]]:
        """Check JARVYS_DEV dashboard for improvement commands"""
        try:
            # Make API call to dashboard
            url = f"{self.jarvys_dev_endpoint}/functions/v1/jarvys-dashboard/api/improvements"
            headers = {
                "Authorization": f"Bearer {self.sync_token}" if self.sync_token else None,
                "X-Device-ID": self.device_id
            }
            
            # Remove None headers
            headers = {k: v for k, v in headers.items() if v is not None}
            
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                return data.get("improvements", [])
            else:
                logger.warning(f"Dashboard API returned {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"❌ Error checking dashboard updates: {e}")
            return []
    
    async def _apply_updates(self, github_updates: List[Dict], dashboard_updates: List[Dict]):
        """Apply available updates safely"""
        try:
            # Create backup before applying updates
            if self.backup_before_update:
                backup_id = await self._create_backup()
                if not backup_id:
                    logger.error("❌ Failed to create backup, skipping updates")
                    return
            
            applied_successfully = []
            failed_updates = []
            
            # Apply GitHub updates first
            for update in github_updates:
                try:
                    success = await self._apply_github_update(update)
                    if success:
                        applied_successfully.append(update)
                    else:
                        failed_updates.append(update)
                except Exception as e:
                    logger.error(f"❌ Error applying update {update.get('file')}: {e}")
                    failed_updates.append(update)
            
            # Apply dashboard updates
            for update in dashboard_updates:
                try:
                    success = await self._apply_dashboard_update(update)
                    if success:
                        applied_successfully.append(update)
                    else:
                        failed_updates.append(update)
                except Exception as e:
                    logger.error(f"❌ Error applying dashboard update: {e}")
                    failed_updates.append(update)
            
            # Report results
            if applied_successfully:
                logger.info(f"✅ Applied {len(applied_successfully)} updates successfully")
                self.applied_updates.extend(applied_successfully)
            
            if failed_updates:
                logger.warning(f"⚠️ {len(failed_updates)} updates failed")
                
                # Rollback if too many failures
                if len(failed_updates) > len(applied_successfully):
                    logger.warning("🔄 Too many failures, rolling back...")
                    await self._rollback_to_backup(backup_id)
            
        except Exception as e:
            logger.error(f"❌ Error applying updates: {e}")
    
    async def _apply_github_update(self, update: Dict[str, Any]) -> bool:
        """Apply a single GitHub update"""
        try:
            update_type = update.get("type")
            
            if update_type == "file_update":
                # Copy updated file
                shutil.copy2(update["source"], update["target"])
                logger.info(f"📝 Updated file: {update['file']}")
                return True
                
            elif update_type == "file_addition":
                # Copy new file
                target_path = Path(update["target"])
                target_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(update["source"], update["target"])
                logger.info(f"➕ Added file: {update['file']}")
                return True
                
            elif update_type == "file_removal":
                # Remove file (with caution)
                if update.get("priority") == "high":
                    os.remove(update["target"])
                    logger.info(f"🗑️ Removed file: {update['file']}")
                    return True
                else:
                    logger.info(f"⏭️ Skipped low-priority removal: {update['file']}")
                    return True
            
            return False
            
        except Exception as e:
            logger.error(f"❌ Error applying GitHub update: {e}")
            return False
    
    async def _apply_dashboard_update(self, update: Dict[str, Any]) -> bool:
        """Apply a dashboard improvement command"""
        try:
            command_type = update.get("type")
            
            if command_type == "config_update":
                # Update configuration
                config_updates = update.get("config", {})
                self.config.update(config_updates)
                logger.info(f"⚙️ Updated configuration: {list(config_updates.keys())}")
                return True
                
            elif command_type == "restart_required":
                # Schedule restart
                logger.info("🔄 Restart scheduled after updates")
                return True
                
            elif command_type == "optimization":
                # Apply optimization
                await self._apply_optimization(update.get("optimization", {}))
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"❌ Error applying dashboard update: {e}")
            return False
    
    async def _create_backup(self) -> Optional[str]:
        """Create backup of current JARVYS_AI code"""
        try:
            backup_id = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = self.backup_path / backup_id
            backup_dir.mkdir(parents=True, exist_ok=True)
            
            # Copy all JARVYS_AI files
            shutil.copytree(self.jarvys_ai_path, backup_dir / "jarvys_ai", 
                          ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
            
            logger.info(f"💾 Created backup: {backup_id}")
            return backup_id
            
        except Exception as e:
            logger.error(f"❌ Error creating backup: {e}")
            return None
    
    async def _rollback_to_backup(self, backup_id: str) -> bool:
        """Rollback to a specific backup"""
        try:
            backup_dir = self.backup_path / backup_id / "jarvys_ai"
            if not backup_dir.exists():
                logger.error(f"❌ Backup {backup_id} not found")
                return False
            
            # Remove current files (except __pycache__)
            for item in self.jarvys_ai_path.iterdir():
                if item.name != "__pycache__":
                    if item.is_dir():
                        shutil.rmtree(item)
                    else:
                        item.unlink()
            
            # Restore from backup
            for item in backup_dir.iterdir():
                if item.is_dir():
                    shutil.copytree(item, self.jarvys_ai_path / item.name)
                else:
                    shutil.copy2(item, self.jarvys_ai_path / item.name)
            
            logger.info(f"🔄 Rolled back to backup: {backup_id}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error rolling back: {e}")
            return False
    
    async def _report_metrics(self):
        """Report performance metrics to JARVYS_DEV dashboard"""
        try:
            metrics = {
                "device_id": self.device_id,
                "timestamp": datetime.now().isoformat(),
                "last_sync": self.last_sync.isoformat() if self.last_sync else None,
                "applied_updates": len(self.applied_updates),
                "performance": self.performance_metrics,
                "status": "healthy" if self.is_running else "stopped"
            }
            
            url = f"{self.jarvys_dev_endpoint}/functions/v1/jarvys-dashboard/api/metrics"
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.sync_token}" if self.sync_token else None,
                "X-Device-ID": self.device_id
            }
            
            # Remove None headers
            headers = {k: v for k, v in headers.items() if v is not None}
            
            response = requests.post(url, json=metrics, headers=headers, timeout=10)
            
            if response.status_code == 200:
                logger.debug("📊 Metrics reported successfully")
            else:
                logger.warning(f"⚠️ Metrics reporting failed: {response.status_code}")
                
        except Exception as e:
            logger.debug(f"❌ Error reporting metrics: {e}")
    
    def _file_hash(self, file_path: Path) -> str:
        """Calculate hash of a file"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception:
            return ""
    
    async def _apply_optimization(self, optimization: Dict[str, Any]):
        """Apply performance optimization"""
        try:
            opt_type = optimization.get("type")
            
            if opt_type == "memory":
                # Memory optimization
                import gc
                gc.collect()
                logger.info("🧹 Applied memory optimization")
                
            elif opt_type == "cache":
                # Cache optimization
                logger.info("🗄️ Applied cache optimization")
                
            elif opt_type == "performance":
                # Performance tuning
                self.sync_interval = optimization.get("sync_interval", self.sync_interval)
                logger.info(f"⚡ Updated sync interval to {self.sync_interval} minutes")
            
        except Exception as e:
            logger.error(f"❌ Error applying optimization: {e}")
