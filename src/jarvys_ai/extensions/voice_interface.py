#!/usr/bin/env python3
"""
🎤 JARVYS_AI - Voice Interface
Interface vocale avec reconnaissance et synthèse vocale
"""

import asyncio
import logging
from typing import Any, Callable, Dict, Optional

logger = logging.getLogger(__name__)


class VoiceInterface:
    """
    🎤 Interface Vocale Intelligente

    Fonctionnalités:
    - Reconnaissance vocale (Speech-to-Text)
    - Synthèse vocale (Text-to-Speech)
    - Commandes vocales naturelles
    - Support multilingue (FR/EN)
    - Activation par mot-clé ("Hey JARVYS")
    - Intégration avec Windows Speech API
    """

    def __init__(self, config: Dict[str, Any]):
        """Initialiser l'interface vocale"""
        self.config = config
        self.is_initialized = False
        self.is_listening = False
        self.wake_word = "hey jarvys"

        # Configuration audio
        self.sample_rate = 16000
        self.language = config.get("language", "fr-FR")
        self.voice_speed = config.get("voice_speed", 1.0)

        # Callbacks
        self.command_callback: Optional[Callable] = None

        # Simulation pour démo
        self.demo_mode = config.get("demo_mode", True)

        logger.info("🎤 Voice Interface initialisé")

    async def initialize(self):
        """Initialiser l'interface vocale"""
        try:
            if self.demo_mode:
                await self._setup_demo_mode()
            else:
                await self._setup_real_voice()

            self.is_initialized = True
            logger.info("🎤 Voice Interface prêt")

        except Exception as e:
            logger.error(f"❌ Erreur initialisation Voice Interface: {e}")
            raise

    def is_initialized(self) -> bool:
        """Vérifier si l'interface est initialisée"""
        return self.is_initialized

    async def _setup_demo_mode(self):
        """Configuration mode démo"""
        logger.info("🎤 Mode démo vocal configuré")

        # Simuler la disponibilité des services vocaux
        self.services_available = {
            "speech_recognition": True,
            "text_to_speech": True,
            "wake_word_detection": True,
        }

    async def _setup_real_voice(self):
        """Configuration services vocaux réels"""
        try:
            # TODO: Implémenter intégration avec:
            # - Windows Speech Recognition
            # - Azure Cognitive Services
            # - Google Speech API
            # - OpenAI Whisper

            logger.info("🎤 Configuration services vocaux réels (TODO)")

            self.services_available = {
                "speech_recognition": False,
                "text_to_speech": False,
                "wake_word_detection": False,
            }

        except Exception as e:
            logger.error(f"❌ Erreur configuration vocale: {e}")
            raise

    def set_command_callback(self, callback: Callable):
        """Définir callback pour traitement commandes"""
        self.command_callback = callback
        logger.info("🔗 Callback commande vocal configuré")

    async def start_listening(self):
        """Démarrer l'écoute vocale"""
        try:
            if not self.is_initialized:
                raise Exception("Interface vocale non initialisée")

            self.is_listening = True
            logger.info("👂 Écoute vocale démarrée")

            if self.demo_mode:
                await self._demo_listening_loop()
            else:
                await self._real_listening_loop()

        except Exception as e:
            logger.error(f"❌ Erreur démarrage écoute: {e}")
            self.is_listening = False
            raise

    async def stop_listening(self):
        """Arrêter l'écoute vocale"""
        self.is_listening = False
        logger.info("🔇 Écoute vocale arrêtée")

    async def _demo_listening_loop(self):
        """Boucle d'écoute en mode démo"""
        logger.info("🎤 Mode démo: simulation écoute vocale")

        # Simulation de commandes vocales reçues
        demo_commands = [
            "Hey JARVYS, lis mes emails",
            "Hey JARVYS, quel est mon planning aujourd'hui",
            "Hey JARVYS, envoie un message à Marie",
            "Hey JARVYS, quelle heure est-il",
        ]

        while self.is_listening:
            await asyncio.sleep(10)  # Simulation délai entre commandes

            if self.command_callback and demo_commands:
                # Simuler réception commande
                command = demo_commands[0]
                demo_commands = demo_commands[1:] + [command]  # Rotation

                logger.info(f"🎤 Commande vocale simulée: {command}")

                # Traiter la commande
                await self._process_voice_command(command)

    async def _real_listening_loop(self):
        """Boucle d'écoute réelle"""
        # TODO: Implémenter écoute réelle avec services vocaux
        logger.info("🎤 Écoute réelle (TODO)")

        while self.is_listening:
            await asyncio.sleep(1)

    async def _process_voice_command(self, text: str):
        """Traiter une commande vocale reconnue"""
        try:
            # Vérifier mot d'activation
            if not self._contains_wake_word(text):
                return

            # Extraire la commande (après le mot d'activation)
            command = self._extract_command(text)

            if command and self.command_callback:
                logger.info(f"🎤 Traitement commande: {command}")

                # Envoyer au système principal
                response = await self.command_callback(command, "voice")

                # Prononcer la réponse
                await self.speak(response)

        except Exception as e:
            logger.error(f"❌ Erreur traitement commande vocale: {e}")
            await self.speak("Désolé, je n'ai pas pu traiter votre commande.")

    def _contains_wake_word(self, text: str) -> bool:
        """Vérifier présence du mot d'activation"""
        text_lower = text.lower()
        return self.wake_word in text_lower or "jarvys" in text_lower

    def _extract_command(self, text: str) -> str:
        """Extraire la commande du texte"""
        text_lower = text.lower()

        # Patterns de reconnaissance
        patterns = [
            f"{self.wake_word},",
            f"{self.wake_word} ",
            "jarvys,",
            "jarvys ",
        ]

        for pattern in patterns:
            if pattern in text_lower:
                # Extraire ce qui suit le pattern
                parts = text_lower.split(pattern, 1)
                if len(parts) > 1:
                    return parts[1].strip()

        return text.strip()

    async def speak(self, text: str, voice: Optional[str] = None):
        """Prononcer un texte"""
        try:
            logger.info(f"🔊 Prononciation: {text[:50]}...")

            if self.demo_mode:
                await self._demo_speak(text)
            else:
                await self._real_speak(text, voice)

        except Exception as e:
            logger.error(f"❌ Erreur prononciation: {e}")

    async def _demo_speak(self, text: str):
        """Simulation prononciation"""
        # Simuler délai de prononciation
        words_count = len(text.split())
        duration = max(1, words_count * 0.3)  # ~0.3s par mot

        logger.info(f"🔊 [DÉMO] Prononciation simulée ({duration:.1f}s): {text}")
        await asyncio.sleep(min(duration, 5))  # Max 5s pour démo

    async def _real_speak(self, text: str, voice: Optional[str] = None):
        """Prononciation réelle"""
        # TODO: Implémenter TTS réel avec:
        # - Windows SAPI
        # - Azure Speech Services
        # - Google Text-to-Speech
        # - Amazon Polly

        logger.info(f"🔊 Prononciation réelle (TODO): {text}")

    async def listen_once(self, timeout: int = 5) -> Optional[str]:
        """Écouter une seule commande avec timeout"""
        try:
            if self.demo_mode:
                return await self._demo_listen_once(timeout)
            else:
                return await self._real_listen_once(timeout)

        except Exception as e:
            logger.error(f"❌ Erreur écoute ponctuelle: {e}")
            return None

    async def _demo_listen_once(self, timeout: int) -> Optional[str]:
        """Écoute ponctuelle simulée"""
        await asyncio.sleep(1)  # Simulation délai reconnaissance

        # Simulation phrases possibles
        demo_phrases = [
            "Oui, c'est parfait",
            "Non merci",
            "Peux-tu répéter s'il te plaît",
            "Lis mes emails",
            "Quel temps fait-il",
        ]

        import random

        return random.choice(demo_phrases)

    async def _real_listen_once(self, timeout: int) -> Optional[str]:
        """Écoute ponctuelle réelle"""
        # TODO: Implémenter reconnaissance vocale ponctuelle
        logger.info(f"🎤 Écoute ponctuelle réelle (TODO) - timeout: {timeout}s")
        return None

    async def process_command(self, command: str) -> str:
        """Traiter une commande liée à l'interface vocale"""
        try:
            command_lower = command.lower()

            if any(word in command_lower for word in ["dire", "parler", "prononcer"]):
                # Extraire texte à prononcer
                text_to_speak = self._extract_text_to_speak(command)
                if text_to_speak:
                    await self.speak(text_to_speak)
                    return f"✅ Texte prononcé: {text_to_speak}"
                else:
                    return "❌ Veuillez spécifier le texte à prononcer"

            elif "écouter" in command_lower or "listen" in command_lower:
                if not self.is_listening:
                    await self.start_listening()
                    return "👂 Écoute vocale démarrée"
                else:
                    return "👂 Écoute vocale déjà active"

            elif "arrêter" in command_lower or "stop" in command_lower:
                if self.is_listening:
                    await self.stop_listening()
                    return "🔇 Écoute vocale arrêtée"
                else:
                    return "🔇 Écoute vocale déjà arrêtée"

            else:
                return await self._handle_voice_info_query()

        except Exception as e:
            logger.error(f"❌ Erreur traitement commande vocale: {e}")
            return f"Erreur lors du traitement vocal: {e}"

    def _extract_text_to_speak(self, command: str) -> Optional[str]:
        """Extraire le texte à prononcer de la commande"""
        import re

        patterns = [
            r'dire\s+["\']([^"\']+)["\']',
            r"dire\s+(.+)",
            r'parler\s+["\']([^"\']+)["\']',
            r"parler\s+(.+)",
            r'prononcer\s+["\']([^"\']+)["\']',
            r"prononcer\s+(.+)",
        ]

        for pattern in patterns:
            match = re.search(pattern, command, re.IGNORECASE)
            if match:
                return match.group(1).strip()

        return None

    async def _handle_voice_info_query(self) -> str:
        """Gérer requête d'information sur l'interface vocale"""
        stats = self.get_voice_stats()

        status = "🟢 Active" if self.is_listening else "🔴 Inactive"

        return f"""🎤 **Interface Vocale JARVYS_AI**

📊 **État**: {status}
🗣️ **Langue**: {self.language}
⚡ **Services**: {stats['services_ready']}/3 prêts

🔧 **Commandes disponibles**:
- "Hey JARVYS, [commande]" - Commande vocale
- "Dire [texte]" - Prononcer texte
- "Écouter" / "Arrêter" - Contrôle écoute

🎯 **Mot d'activation**: "{self.wake_word}"

Comment puis-je vous aider avec l'interface vocale ?"""

    def get_voice_stats(self) -> Dict[str, Any]:
        """Obtenir statistiques interface vocale"""
        services_ready = sum(self.services_available.values())

        return {
            "is_listening": self.is_listening,
            "services_ready": services_ready,
            "language": self.language,
            "wake_word": self.wake_word,
            "demo_mode": self.demo_mode,
        }

    def get_stats(self) -> Dict[str, Any]:
        """Obtenir statistiques du module"""
        return {
            "is_initialized": self.is_initialized,
            "is_listening": self.is_listening,
            "demo_mode": self.demo_mode,
            "language": self.language,
            "services_available": self.services_available,
            "version": "1.0.0",
        }
