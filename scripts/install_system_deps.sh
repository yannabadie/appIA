#!/bin/bash
# install_system_deps.sh - Install system dependencies for JARVYS_AI

set -e  # Exit on any error

echo "🔧 Installing system dependencies for JARVYS_AI..."

# Update package lists
echo "📦 Updating package lists..."
sudo apt-get update

# Install audio system dependencies
echo "🎵 Installing audio system dependencies..."
sudo apt-get install -y portaudio19-dev python3-pyaudio
sudo apt-get install -y libasound2-dev libpulse-dev

# Install build tools
echo "🛠️ Installing build tools..."
sudo apt-get install -y build-essential python3-dev

# Install additional system tools that might be needed
echo "📋 Installing additional system tools..."
sudo apt-get install -y pkg-config
sudo apt-get install -y libffi-dev

# Clean up
echo "🧹 Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "✅ System dependencies installed successfully!"
echo "📝 Installed packages:"
echo "   - portaudio19-dev (for PyAudio)"
echo "   - python3-pyaudio (system PyAudio)"
echo "   - libasound2-dev (ALSA development)"
echo "   - libpulse-dev (PulseAudio development)"
echo "   - build-essential (compilation tools)"
echo "   - python3-dev (Python development headers)"
echo "   - pkg-config (package configuration)"
echo "   - libffi-dev (foreign function interface)"