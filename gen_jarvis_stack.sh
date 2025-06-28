#!/bin/bash
set -e

echo "=== [JARVIS AI] Génération auto de l'écosystème... ==="

# 1. Arborescence projet
mkdir -p scripts config logs

# 2. Script pulse_wsl_init.sh
cat > scripts/pulse_wsl_init.sh <<'EOF'
#!/bin/bash
# Fixe PULSE_SERVER pour WSL2 à chaque login
PULSE_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
export PULSE_SERVER="tcp:$PULSE_IP"
echo "[Jarvis] PULSE_SERVER défini à $PULSE_SERVER"
paplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || true
EOF
chmod +x scripts/pulse_wsl_init.sh

# 3. Script start_jarvis_stack.sh
cat > scripts/start_jarvis_stack.sh <<'EOF'
#!/bin/bash
echo "=== [JARVIS AI] Initialisation complète ==="
cd "$(dirname "$0")/.."
source ~/jarvisenv/bin/activate
bash ./scripts/pulse_wsl_init.sh
python3 jarvis_voice.py &
python3 jarvis_webui.py &
python3 agent_core.py &
echo "=== [JARVIS AI] Tout est lancé ! ==="
EOF
chmod +x scripts/start_jarvis_stack.sh

# 4. Script check_audio_chain.sh
cat > scripts/check_audio_chain.sh <<'EOF'
#!/bin/bash
echo "[Audio Test] Lecture test..."
paplay /usr/share/sounds/alsa/Front_Center.wav || echo "Echec sortie audio"
echo "[Audio Test] Test micro (parle 3 sec puis replay)..."
arecord -d 3 -f cd /tmp/testmic.wav && aplay /tmp/testmic.wav
EOF
chmod +x scripts/check_audio_chain.sh

# 5. requirements.txt minimal (à compléter au besoin)
cat > config/requirements.txt <<EOF
TTS
torch
torchaudio
sounddevice
numpy
soundfile
openai-whisper
streamlit
EOF

# 6. Exemple de config YAML (à adapter)
cat > config/jarvis_settings.yaml <<EOF
# Config Jarvis AI (à compléter)
lang: fr
voice: tts_models/fr/mai/tacotron2-DDC
ui_port: 8501
memory_dir: logs/
EOF

# 7. Log file initial
touch logs/jarvis_ai.log

echo "=== [JARVIS AI] Dossiers, scripts, requirements et config générés. ==="
echo "▶️ À faire :"
echo "  - Ajoute/ajuste tes scripts python dans le dossier racine."
echo "  - Place ce qui suit dans ~/.bashrc ou source-le à chaque login pour l'audio :"
echo "      source \$PWD/scripts/pulse_wsl_init.sh"
echo "  - Pour lancer tout Jarvis AI : ./scripts/start_jarvis_stack.sh"
echo "  - Pour tester l'audio : ./scripts/check_audio_chain.sh"
