#!/usr/bin/env python3
"""
🧪 JARVYS_AI - Tests Complets
Test de tous les modules et fonctionnalités de JARVYS_AI
"""

import sys
import os
from pathlib import Path
import logging

# Ajouter le répertoire src au PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent / "src"))

# Configurer logging pour les tests
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TestJarvysAICore:
    """Tests pour les composants principaux de JARVYS_AI"""
    
    def __init__(self):
        """Configuration pour chaque test"""
        self.config = {
            'openai_api_key': 'test-key',
            'supabase_url': 'test-url',
            'supabase_key': 'test-key',
            'environment': 'test',
            'demo_mode': True,
            'voice_enabled': False,  # Désactiver pour les tests
            'email_enabled': False,
            'cloud_enabled': False,
            'auto_improve': False,
            'debug': True
        }
    
    def test_01_import_main_module(self):
        """Test 1: Import du module principal"""
        try:
            from jarvys_ai import JarvysAI
            logger.info("✅ Test 1: Import module principal réussi")
            return True
        except Exception as e:
            logger.error(f"❌ Test 1: Échec import principal: {e}")
            return False
    
    def test_02_intelligence_core_import(self):
        """Test 2: Import Intelligence Core"""
        try:
            from jarvys_ai.intelligence_core import IntelligenceCore
            core = IntelligenceCore(self.config)
            logger.info("✅ Test 2: Intelligence Core importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 2: Échec Intelligence Core: {e}")
            return False
    
    def test_03_digital_twin_import(self):
        """Test 3: Import Digital Twin"""
        try:
            from jarvys_ai.digital_twin import DigitalTwin
            twin = DigitalTwin(self.config)
            logger.info("✅ Test 3: Digital Twin importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 3: Échec Digital Twin: {e}")
            return False
    
    def test_04_continuous_improvement_import(self):
        """Test 4: Import Continuous Improvement"""
        try:
            from jarvys_ai.continuous_improvement import ContinuousImprovement
            improvement = ContinuousImprovement(self.config)
            logger.info("✅ Test 4: Continuous Improvement importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 4: Échec Continuous Improvement: {e}")
            return False
    
    def test_05_fallback_engine_import(self):
        """Test 5: Import Fallback Engine"""
        try:
            from jarvys_ai.fallback_engine import FallbackEngine
            fallback = FallbackEngine(self.config)
            logger.info("✅ Test 5: Fallback Engine importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 5: Échec Fallback Engine: {e}")
            return False
    
    def test_06_enhanced_fallback_engine_import(self):
        """Test 6: Import Enhanced Fallback Engine"""
        try:
            from jarvys_ai.enhanced_fallback_engine import EnhancedFallbackEngine
            enhanced_fallback = EnhancedFallbackEngine(self.config)
            logger.info("✅ Test 6: Enhanced Fallback Engine importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 6: Échec Enhanced Fallback Engine: {e}")
            return False
    
    def test_07_dashboard_integration_import(self):
        """Test 7: Import Dashboard Integration"""
        try:
            from jarvys_ai.dashboard_integration import SupabaseDashboardIntegration
            # Note: This needs a JARVYS_AI instance, so we'll skip actual instantiation
            logger.info("✅ Test 7: Dashboard Integration importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 7: Échec Dashboard Integration: {e}")
            return False

class TestJarvysAIExtensions:
    """Tests pour les extensions de JARVYS_AI"""
    
    def __init__(self):
        """Configuration pour chaque test"""
        self.config = {
            'demo_mode': True,
            'debug': True,
            'voice_enabled': False,
            'email_enabled': False,
            'cloud_enabled': False
        }
    
    def test_08_email_manager_import(self):
        """Test 8: Import Email Manager"""
        try:
            from jarvys_ai.extensions.email_manager import EmailManager
            email_mgr = EmailManager(self.config)
            logger.info("✅ Test 8: Email Manager importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 8: Échec Email Manager: {e}")
            return False
    
    def test_09_voice_interface_import(self):
        """Test 9: Import Voice Interface"""
        try:
            from jarvys_ai.extensions.voice_interface import VoiceInterface
            voice = VoiceInterface(self.config)
            logger.info("✅ Test 9: Voice Interface importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 9: Échec Voice Interface: {e}")
            return False
    
    def test_10_cloud_manager_import(self):
        """Test 10: Import Cloud Manager"""
        try:
            from jarvys_ai.extensions.cloud_manager import CloudManager
            cloud = CloudManager(self.config)
            logger.info("✅ Test 10: Cloud Manager importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 10: Échec Cloud Manager: {e}")
            return False
    
    def test_11_file_manager_import(self):
        """Test 11: Import File Manager"""
        try:
            from jarvys_ai.extensions.file_manager import FileManager
            file_mgr = FileManager(self.config)
            logger.info("✅ Test 11: File Manager importé")
            return True
        except Exception as e:
            logger.error(f"❌ Test 11: Échec File Manager: {e}")
            return False

class TestJarvysAIIntegration:
    """Tests d'intégration complète"""
    
    def test_12_jarvys_ai_initialization(self):
        """Test 12: Initialisation complète de JARVYS_AI"""
        try:
            from jarvys_ai import JarvysAI
            
            # Configuration de test
            config = {
                'openai_api_key': 'test-key',
                'supabase_url': 'test-url',
                'supabase_key': 'test-key',
                'environment': 'test',
                'demo_mode': True,
                'voice_enabled': False,
                'email_enabled': False,
                'cloud_enabled': False,
                'auto_improve': False,
                'debug': True
            }
            
            # Create instance (without mocking for now to see what fails)
            jarvys = JarvysAI(config)
            
            # Vérifications de base
            if jarvys and jarvys.config and jarvys.intelligence_core:
                logger.info("✅ Test 12: JARVYS_AI initialisé avec succès")
                return True
            else:
                logger.error("❌ Test 12: JARVYS_AI non initialisé correctement")
                return False
                
        except Exception as e:
            logger.error(f"❌ Test 12: Échec initialisation JARVYS_AI: {e}")
            return False

class TestRunner:
    """Gestionnaire d'exécution des tests"""
    
    def __init__(self):
        self.total_tests = 12
        self.passed_tests = 0
        self.failed_tests = []
    
    def run_all_tests(self):
        """Exécuter tous les tests"""
        logger.info("🧪 Début des tests JARVYS_AI")
        logger.info("=" * 60)
        
        # Tests des composants principaux
        core_tester = TestJarvysAICore()
        core_results = []
        core_results.append(core_tester.test_01_import_main_module())
        core_results.append(core_tester.test_02_intelligence_core_import())
        core_results.append(core_tester.test_03_digital_twin_import())
        core_results.append(core_tester.test_04_continuous_improvement_import())
        core_results.append(core_tester.test_05_fallback_engine_import())
        core_results.append(core_tester.test_06_enhanced_fallback_engine_import())
        core_results.append(core_tester.test_07_dashboard_integration_import())
        
        # Tests des extensions
        ext_tester = TestJarvysAIExtensions()
        ext_results = []
        ext_results.append(ext_tester.test_08_email_manager_import())
        ext_results.append(ext_tester.test_09_voice_interface_import())
        ext_results.append(ext_tester.test_10_cloud_manager_import())
        ext_results.append(ext_tester.test_11_file_manager_import())
        
        # Tests d'intégration
        int_tester = TestJarvysAIIntegration()
        int_results = []
        int_results.append(int_tester.test_12_jarvys_ai_initialization())
        
        # Calculer les résultats
        all_results = core_results + ext_results + int_results
        passed_count = sum(1 for result in all_results if result)
        failed_count = sum(1 for result in all_results if not result)
        
        # Affichage des résultats
        logger.info("=" * 60)
        logger.info("📊 RÉSULTATS DES TESTS")
        logger.info("=" * 60)
        logger.info(f"Total des tests: {len(all_results)}/{self.total_tests}")
        logger.info(f"✅ Réussis: {passed_count}")
        logger.info(f"❌ Échecs: {failed_count}")
        
        success_rate = (passed_count / len(all_results)) * 100 if len(all_results) > 0 else 0
        logger.info(f"📈 Taux de réussite: {success_rate:.1f}%")
        
        if failed_count == 0:
            logger.info("🎉 TOUS LES TESTS SONT PASSÉS!")
            return True
        else:
            logger.warning("⚠️ Certains tests ont échoué")
            return False

def main():
    """Point d'entrée principal"""
    if len(sys.argv) > 1 and sys.argv[1] == "--health-check":
        # Mode health check pour Docker
        try:
            from jarvys_ai import JarvysAI
            logger.info("✅ Health check: JARVYS_AI importable")
            return 0
        except Exception as e:
            logger.error(f"❌ Health check échoué: {e}")
            return 1
    
    # Exécution normale des tests
    runner = TestRunner()
    success = runner.run_all_tests()
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())