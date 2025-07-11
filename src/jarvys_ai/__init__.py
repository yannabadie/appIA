"""
🤖 JARVYS_AI - Digital Twin de Yann Abadie
Agent d'Intelligence Locale/Hybride avec capacités humaines illimitées

JARVYS_AI est le jumeau numérique de Yann Abadie, conçu pour fournir:
- Interface voix/texte naturelle
- Gestion email (Outlook/Gmail) 
- Intégration cloud (GCP/MCP)
- Gestion fichiers locale/cloud
- Support Docker Windows 11
- Amélioration continue via JARVYS_DEV
"""

__version__ = "1.0.0"
__author__ = "JARVYS_DEV"
__description__ = "Digital Twin de Yann Abadie - Agent d'Intelligence Hybride"

from .intelligence_core import IntelligenceCore
from .digital_twin import DigitalTwin
from .continuous_improvement import ContinuousImprovement
from .fallback_engine import FallbackEngine
from .main import JarvysAI

__all__ = [
    "IntelligenceCore",
    "DigitalTwin",
    "ContinuousImprovement",
    "FallbackEngine",
    "JarvysAI"
]
