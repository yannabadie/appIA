#!/usr/bin/env python3
"""
🚀 JARVYS_AI - Launcher Script
Script de lancement pour JARVYS_AI
"""

import sys
import os
import asyncio
from pathlib import Path

# Ajouter src au PYTHONPATH
src_path = str(Path(__file__).parent / "src")
sys.path.insert(0, src_path)

def main():
    """Point d'entrée principal"""
    try:
        from jarvys_ai.main import main as jarvys_main
        return asyncio.run(jarvys_main())
    except KeyboardInterrupt:
        print("🔄 Arrêt demandé par l'utilisateur")
        return 0
    except Exception as e:
        print(f"❌ Erreur lancement JARVYS_AI: {e}")
        return 1

if __name__ == "__main__":
    exit(main())