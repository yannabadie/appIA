#!/usr/bin/env python3
"""
🤖 JARVYS_AI - Digital Twin de Yann Abadie
Agent d'Intelligence Hybride Local/Cloud

Module principal pour l'initialisation et l'orchestration de tous les composants
"""

import asyncio
import logging
import os
import sys
from pathlib import Path
from typing import Dict, Any, Optional
from datetime import datetime

from .intelligence_core import IntelligenceCore
from .digital_twin import DigitalTwin
from .continuous_improvement import ContinuousImprovement
from .fallback_engine import FallbackEngine
from .extensions.email_manager import EmailManager
from .extensions.voice_interface import VoiceInterface
from .extensions.cloud_manager import CloudManager
from .extensions.file_manager import FileManager

# Configuration logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - JARVYS_AI - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class JarvysAI:
    """
    🤖 JARVYS_AI - Agent d'Intelligence Hybride
    
    Jumeau numérique de Yann Abadie avec capacités:
    - Interface voix/texte naturelle 
    - Gestion emails (Outlook/Gmail)
    - Intégration cloud (GCP/MCP)
    - Gestion fichiers locale/cloud
    - Support Docker Windows 11
    - Auto-amélioration continue
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialiser JARVYS_AI avec configuration"""
        self.config = config or self._load_default_config()
        self.session_id = datetime.now().isoformat()
        
        # Composants principaux
        self.intelligence_core = IntelligenceCore(self.config)
        self.digital_twin = DigitalTwin(self.config)
        self.continuous_improvement = ContinuousImprovement(self.config)
        self.fallback_engine = FallbackEngine(self.config)
        
        # Extensions
        self.extensions = {
            'email': EmailManager(self.config),
            'voice': VoiceInterface(self.config),
            'cloud': CloudManager(self.config),
            'files': FileManager(self.config)
        }
        
        # État système
        self.is_running = False
        self.tasks = []
        
        logger.info("🤖 JARVYS_AI initialisé - Digital Twin prêt")
        
    def _load_default_config(self) -> Dict[str, Any]:
        """Charger configuration par défaut"""
        return {
            'openai_api_key': os.getenv('OPENAI_API_KEY'),
            'supabase_url': os.getenv('SUPABASE_URL'),
            'supabase_key': os.getenv('SUPABASE_KEY'),
            'environment': os.getenv('ENVIRONMENT', 'local'),
            'voice_enabled': True,
            'email_enabled': True,
            'cloud_enabled': True,
            'auto_improve': True,
            'debug': False
        }
    
    async def start(self):
        """Démarrer JARVYS_AI et tous ses composants"""
        try:
            logger.info("🚀 Démarrage de JARVYS_AI...")
            self.is_running = True
            
            # Initialiser composants principaux
            await self.intelligence_core.initialize()
            await self.digital_twin.initialize()
            await self.continuous_improvement.initialize()
            await self.fallback_engine.initialize()
            
            # Initialiser extensions
            for name, extension in self.extensions.items():
                try:
                    await extension.initialize()
                    logger.info(f"✅ Extension {name} initialisée")
                except Exception as e:
                    logger.warning(f"⚠️ Extension {name} non disponible: {e}")
            
            # Configurer callbacks
            self.extensions['voice'].set_command_callback(self.process_command)
            
            # Démarrer amélioration continue
            if self.config.get('auto_improve'):
                asyncio.create_task(self.continuous_improvement.start_continuous_monitoring())
            
            # Démarrer monitoring fallback
            asyncio.create_task(self.fallback_engine.monitor_quotas())
            
            # Démarrer la boucle principale
            await self._main_loop()
            
        except Exception as e:
            logger.error(f"❌ Erreur démarrage JARVYS_AI: {e}")
            raise
    
    async def stop(self):
        """Arrêter JARVYS_AI proprement"""
        logger.info("🛑 Arrêt de JARVYS_AI...")
        self.is_running = False
        
        # Arrêter les tâches
        for task in self.tasks:
            task.cancel()
        
        # Sauvegarder l'état
        await self.digital_twin.save_state()
        
        logger.info("✅ JARVYS_AI arrêté proprement")
    
    async def _main_loop(self):
        """Boucle principale d'exécution"""
        while self.is_running:
            try:
                # Vérifier les tâches en cours
                await self._process_tasks()
                
                # Vérifier les amélirations disponibles
                if self.config.get('auto_improve'):
                    await self._check_improvements()
                
                # Attendre avant la prochaine itération
                await asyncio.sleep(1)
                
            except KeyboardInterrupt:
                logger.info("🔄 Interruption clavier - arrêt en cours...")
                break
            except Exception as e:
                logger.error(f"❌ Erreur boucle principale: {e}")
                await asyncio.sleep(5)
    
    async def _process_tasks(self):
        """Traiter les tâches en attente"""
        # TODO: Implémenter gestion des tâches
        pass
    
    async def _check_improvements(self):
        """Vérifier les améliorations depuis JARVYS_DEV"""
        # TODO: Implémenter check améliorations
        pass
    
    async def process_command(self, command: str, interface: str = "text") -> str:
        """
        Traiter une commande utilisateur
        
        Args:
            command: Commande à traiter
            interface: Interface utilisée (text, voice, email)
            
        Returns:
            Réponse à la commande
        """
        try:
            logger.info(f"📝 Commande reçue ({interface}): {command[:50]}...")
            
            # Analyser la commande via intelligence core
            analysis = await self.intelligence_core.analyze_command(command)
            
            # Router vers l'extension appropriée
            response = await self._route_command(analysis, command)
            
            # Mettre à jour le jumeau numérique
            await self.digital_twin.update_interaction(command, response, interface)
            
            return response
            
        except Exception as e:
            error_msg = f"❌ Erreur traitement commande: {e}"
            logger.error(error_msg)
            return error_msg
    
    async def _route_command(self, analysis: Dict[str, Any], command: str) -> str:
        """Router la commande vers l'extension appropriée"""
        command_type = analysis.get('type', 'general')
        
        if command_type == 'email':
            return await self.extensions['email'].process_command(command)
        elif command_type == 'file':
            return await self.extensions['files'].process_command(command)
        elif command_type == 'cloud':
            return await self.extensions['cloud'].process_command(command)
        else:
            return await self.intelligence_core.process_general_command(command)
    
    def get_status(self) -> Dict[str, Any]:
        """Obtenir le statut actuel de JARVYS_AI"""
        return {
            'is_running': self.is_running,
            'session_id': self.session_id,
            'extensions': {
                name: ext.is_initialized() 
                for name, ext in self.extensions.items()
            },
            'tasks_count': len(self.tasks),
            'continuous_improvement': self.continuous_improvement.get_improvement_status() if hasattr(self, 'continuous_improvement') else {},
            'fallback_engine': self.fallback_engine.get_fallback_status() if hasattr(self, 'fallback_engine') else {},
            'version': '1.0.0'
        }


async def main():
    """Point d'entrée principal"""
    jarvys = JarvysAI()
    
    try:
        await jarvys.start()
    except KeyboardInterrupt:
        logger.info("🔄 Arrêt demandé par l'utilisateur")
    finally:
        await jarvys.stop()


if __name__ == "__main__":
    asyncio.run(main())
