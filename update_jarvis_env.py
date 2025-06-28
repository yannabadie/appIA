import os
import subprocess
import sys
import platform
import time

# Liste des modules et versions minimum recommandées pour Jarvis AI 2025
REQUIRED_MODULES = [
    "streamlit>=1.46.0",
    "openai>=1.14.2",
    "google-generativeai>=0.8.5",
    "ollama>=0.5.1",
    "python-dotenv>=1.1.1",
    "streamlit-extras>=0.7.1",
    "protobuf>=5.27.3",
    "pandas",
    "requests",
    "numpy",
    "rich",
    "tenacity",
]

def run(cmd, shell=True):
    """Helper pour lancer une commande système proprement et afficher la sortie."""
    print(f"\n[RUN] {cmd}")
    res = subprocess.run(cmd, shell=shell, capture_output=True, text=True)
    if res.stdout:
        print(res.stdout)
    if res.stderr:
        print("STDERR:", res.stderr)
    return res

def clean_venv(venv_path=".venv"):
    """Supprime proprement l'environnement virtuel existant."""
    import shutil
    if os.path.exists(venv_path):
        print(f"[INFO] Suppression de l'ancien venv {venv_path}...")
        shutil.rmtree(venv_path)

def create_venv(venv_path=".venv"):
    """Crée un nouvel environnement virtuel."""
    run(f"python -m venv {venv_path}")

def activate_venv_cmd(venv_path=".venv"):
    """Renvoie la commande d'activation venv selon l'OS."""
    if platform.system().lower() == "windows":
        return os.path.join(venv_path, "Scripts", "activate")
    else:
        return f"source {venv_path}/bin/activate"

def pip_install(modules, venv_path=".venv"):
    """Installe les modules requis dans le venv."""
    # Construction du chemin pip
    pip_exec = os.path.join(venv_path, "Scripts" if platform.system().lower() == "windows" else "bin", "pip")
    cmd = [pip_exec, "install", "--upgrade", "pip"] + modules
    print("[INFO] Installation/Upgrade des modules...")
    subprocess.check_call(cmd)

def check_conflicts(venv_path=".venv"):
    """Utilise pip check pour afficher les conflits éventuels."""
    pip_exec = os.path.join(venv_path, "Scripts" if platform.system().lower() == "windows" else "bin", "pip")
    run(f"{pip_exec} check")

def freeze_reqs(venv_path=".venv"):
    """Affiche un requirements.txt de l'état actuel"""
    pip_exec = os.path.join(venv_path, "Scripts" if platform.system().lower() == "windows" else "bin", "pip")
    run(f"{pip_exec} freeze")

def main():
    venv_path = ".venv"

    print("\n=== [JARVIS AUTO-SETUP & UPDATE] ===\n")

    # 1. Optionnel : nettoyer l'ancien venv pour repartir de zéro
    user_clean = input("Voulez-vous supprimer et réinstaller le venv (O/n) ? ").strip().lower()
    if user_clean in ["", "o", "oui", "y", "yes"]:
        clean_venv(venv_path)

    # 2. Créer le venv s'il n'existe pas
    if not os.path.exists(venv_path):
        create_venv(venv_path)
        print(f"[INFO] Environnement virtuel créé : {venv_path}")

    # 3. Installer/mettre à jour les modules
    pip_install(REQUIRED_MODULES, venv_path)

    # 4. Vérifier les conflits de dépendances
    print("\n=== Vérification des conflits de dépendances (pip check) ===\n")
    check_conflicts(venv_path)

    # 5. Afficher le requirements.txt généré (état final des versions)
    print("\n=== Etat final des packages installés ===\n")
    freeze_reqs(venv_path)

    print("\n✅ Environnement Jarvis prêt. Active ton venv puis lance :\n    streamlit run web_ui_streamlit.py\n")
    print("Pour activer :")
    print(f"    {activate_venv_cmd(venv_path)}")
    print("\n---\n")

if __name__ == "__main__":
    main()
