#!/usr/bin/env python3
"""
👤 JARVYS_AI - Digital Twin de Yann Abadie
Module de personnalisation et apprentissage continu
"""

import json
import logging
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict

logger = logging.getLogger(__name__)


class DigitalTwin:
    """
    👤 Jumeau Numérique de Yann Abadie

    Responsable de:
    - Maintenir le profil et les préférences utilisateur
    - Apprendre des interactions
    - Personnaliser les réponses
    - Conserver l'historique et le contexte
    - Synchroniser avec JARVYS_DEV
    """

    def __init__(self, config: Dict[str, Any]):
        """Initialiser le jumeau numérique"""
        self.config = config
        self.user_profile = {}
        self.interaction_history = []
        self.preferences = {}
        self.context_memory = {}
        self.is_initialized = False

        # Chemin de sauvegarde local
        self.data_dir = Path.home() / ".jarvys_ai"
        self.profile_file = self.data_dir / "user_profile.json"
        self.history_file = self.data_dir / "interaction_history.json"

        logger.info("👤 Digital Twin initialisé")

    async def initialize(self):
        """Initialiser le jumeau numérique"""
        try:
            # Créer répertoire de données
            self.data_dir.mkdir(exist_ok=True)

            # Charger profil existant
            await self._load_user_profile()

            # Charger historique
            await self._load_interaction_history()

            # Initialiser profil par défaut si nécessaire
            if not self.user_profile:
                await self._create_default_profile()

            self.is_initialized = True
            logger.info("👤 Digital Twin prêt")

        except Exception as e:
            logger.error(f"❌ Erreur initialisation Digital Twin: {e}")
            raise

    async def _load_user_profile(self):
        """Charger le profil utilisateur"""
        try:
            if self.profile_file.exists():
                with open(self.profile_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.user_profile = data.get("profile", {})
                    self.preferences = data.get("preferences", {})
                    logger.info("✅ Profil utilisateur chargé")
            else:
                logger.info("📝 Nouveau profil utilisateur")

        except Exception as e:
            logger.error(f"❌ Erreur chargement profil: {e}")

    async def _load_interaction_history(self):
        """Charger l'historique des interactions"""
        try:
            if self.history_file.exists():
                with open(self.history_file, "r", encoding="utf-8") as f:
                    self.interaction_history = json.load(f)
                    logger.info(
                        f"📚 {len(self.interaction_history)} interactions chargées"
                    )
            else:
                self.interaction_history = []
                logger.info("📝 Nouvel historique d'interactions")

        except Exception as e:
            logger.error(f"❌ Erreur chargement historique: {e}")
            self.interaction_history = []

    async def _create_default_profile(self):
        """Créer profil par défaut pour Yann Abadie"""
        self.user_profile = {
            "name": "Yann Abadie",
            "role": "CEO & Fondateur",
            "company": "Appia",
            "email_primary": "yann@appia.fr",
            "language": "fr",
            "timezone": "Europe/Paris",
            "work_hours": {"start": "09:00", "end": "18:00"},
            "created_at": datetime.now().isoformat(),
            "version": "1.0.0",
        }

        self.preferences = {
            "communication_style": "professional_friendly",
            "notification_frequency": "normal",
            "auto_responses": True,
            "voice_enabled": True,
            "email_auto_sort": True,
            "cloud_sync": True,
            "privacy_level": "standard",
        }

        await self.save_profile()
        logger.info("👤 Profil par défaut créé pour Yann Abadie")

    async def update_interaction(self, command: str, response: str, interface: str):
        """Enregistrer une nouvelle interaction"""
        try:
            interaction = {
                "id": str(uuid.uuid4()),
                "timestamp": datetime.now().isoformat(),
                "command": command,
                "response": response,
                "interface": interface,
                "sentiment": self._analyze_sentiment(command),
                "category": self._categorize_interaction(command),
            }

            self.interaction_history.append(interaction)

            # Garder seulement les 1000 dernières interactions
            if len(self.interaction_history) > 1000:
                self.interaction_history = self.interaction_history[-1000:]

            # Apprendre de l'interaction
            await self._learn_from_interaction(interaction)

            # Sauvegarder
            await self.save_history()

            logger.info(f"📝 Interaction enregistrée: {interface}")

        except Exception as e:
            logger.error(f"❌ Erreur enregistrement interaction: {e}")

    def _analyze_sentiment(self, text: str) -> str:
        """Analyser le sentiment d'un texte (simple)"""
        positive_words = [
            "merci",
            "parfait",
            "excellent",
            "super",
            "génial",
            "bravo",
        ]
        negative_words = [
            "problème",
            "erreur",
            "bug",
            "cassé",
            "marche pas",
            "nul",
        ]

        text_lower = text.lower()

        pos_count = sum(1 for word in positive_words if word in text_lower)
        neg_count = sum(1 for word in negative_words if word in text_lower)

        if pos_count > neg_count:
            return "positive"
        elif neg_count > pos_count:
            return "negative"
        else:
            return "neutral"

    def _categorize_interaction(self, command: str) -> str:
        """Catégoriser l'interaction"""
        categories = {
            "email": ["email", "mail", "message"],
            "file": ["fichier", "file", "document"],
            "cloud": ["cloud", "deploy", "server"],
            "system": ["status", "état", "info"],
            "personal": ["aide", "help", "comment"],
        }

        command_lower = command.lower()

        for category, keywords in categories.items():
            if any(keyword in command_lower for keyword in keywords):
                return category

        return "general"

    async def _learn_from_interaction(self, interaction: Dict[str, Any]):
        """Apprendre de l'interaction pour personnaliser"""
        try:
            category = interaction["category"]
            sentiment = interaction["sentiment"]

            # Mettre à jour les préférences basées sur l'usage
            if category not in self.preferences:
                self.preferences[f"{category}_usage"] = 0

            self.preferences[f"{category}_usage"] += 1

            # Adapter le style de communication
            if sentiment == "negative":
                self.preferences["communication_style"] = "formal"
            elif sentiment == "positive":
                self.preferences["communication_style"] = "friendly"

            logger.debug(f"🧠 Apprentissage: {category} ({sentiment})")

        except Exception as e:
            logger.error(f"❌ Erreur apprentissage: {e}")

    async def save_profile(self):
        """Sauvegarder le profil utilisateur"""
        try:
            data = {
                "profile": self.user_profile,
                "preferences": self.preferences,
                "updated_at": datetime.now().isoformat(),
            }

            with open(self.profile_file, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

            logger.debug("💾 Profil sauvegardé")

        except Exception as e:
            logger.error(f"❌ Erreur sauvegarde profil: {e}")

    async def save_history(self):
        """Sauvegarder l'historique des interactions"""
        try:
            with open(self.history_file, "w", encoding="utf-8") as f:
                json.dump(self.interaction_history, f, indent=2, ensure_ascii=False)

            logger.debug("💾 Historique sauvegardé")

        except Exception as e:
            logger.error(f"❌ Erreur sauvegarde historique: {e}")

    async def save_state(self):
        """Sauvegarder l'état complet"""
        await self.save_profile()
        await self.save_history()
        logger.info("💾 État complet sauvegardé")

    def get_user_context(self) -> Dict[str, Any]:
        """Obtenir le contexte utilisateur actuel"""
        recent_interactions = (
            self.interaction_history[-10:] if self.interaction_history else []
        )

        return {
            "profile": self.user_profile,
            "preferences": self.preferences,
            "recent_interactions": len(recent_interactions),
            "total_interactions": len(self.interaction_history),
            "last_interaction": (
                recent_interactions[-1]["timestamp"] if recent_interactions else None
            ),
            "most_used_category": self._get_most_used_category(),
        }

    def _get_most_used_category(self) -> str:
        """Obtenir la catégorie la plus utilisée"""
        if not self.interaction_history:
            return "general"

        categories = {}
        for interaction in self.interaction_history:
            category = interaction.get("category", "general")
            categories[category] = categories.get(category, 0) + 1

        return max(categories, key=categories.get)

    def get_personalized_response(self, base_response: str, context: str = "") -> str:
        """Personnaliser une réponse selon le profil"""
        style = self.preferences.get("communication_style", "professional_friendly")

        if style == "formal":
            if not base_response.startswith(("Monsieur", "Bonjour")):
                base_response = f"Monsieur Abadie, {base_response.lower()}"
        elif style == "friendly":
            if not base_response.startswith(("Salut", "Hey", "Coucou")):
                base_response = f"Salut Yann ! {base_response}"

        return base_response

    def get_stats(self) -> Dict[str, Any]:
        """Obtenir statistiques du jumeau numérique"""
        return {
            "is_initialized": self.is_initialized,
            "profile_loaded": bool(self.user_profile),
            "total_interactions": len(self.interaction_history),
            "preferences_count": len(self.preferences),
            "data_dir": str(self.data_dir),
            "version": "1.0.0",
        }
