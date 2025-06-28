# Powershell minimal (full_auto.ps1)
python patcher_jarvis.py
python -m venv .venv
.venv\Scripts\Activate
pip install -r requirements.txt
python setup_ollama_mistral.py  # gère l’install/check modèle
echo "Tout patché. Lance python web_ui.py"