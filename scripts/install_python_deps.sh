#!/bin/bash
# install_python_deps.sh - Install Python dependencies for JARVYS_AI

set -e  # Exit on any error

echo "📦 Installing Python dependencies for JARVYS_AI..."

# Upgrade pip and essential tools
echo "⬆️ Upgrading pip and build tools..."
pip install --upgrade pip setuptools wheel

# Install main requirements
echo "📋 Installing main requirements..."
pip install -r requirements.txt

# Try to install PyAudio separately with fallback
echo "🎵 Installing PyAudio..."
if pip install pyaudio>=0.2.11; then
    echo "✅ PyAudio installed successfully via pip"
else
    echo "⚠️ PyAudio pip install failed, checking system package..."
    python3 -c "import pyaudio; print('✅ PyAudio available via system package')" 2>/dev/null || {
        echo "❌ PyAudio not available via system package either"
        echo "🔧 Please ensure 'python3-pyaudio' system package is installed"
        exit 1
    }
fi

# Verify key packages are importable
echo "🔍 Verifying key packages..."
python3 -c "
try:
    import openai
    import supabase
    import fastapi
    import numpy
    print('✅ Core packages verification passed')
except ImportError as e:
    print(f'❌ Package verification failed: {e}')
    exit(1)
"

# Audio verification (non-critical)
echo "🎵 Verifying audio capabilities..."
python3 -c "
try:
    import soundfile
    import speechrecognition
    import pyttsx3
    print('✅ Audio packages verification passed')
except ImportError as e:
    print(f'⚠️ Audio package verification failed: {e}')
    print('   (This may be okay for headless environments)')
"

echo "✅ Python dependencies installed successfully!"