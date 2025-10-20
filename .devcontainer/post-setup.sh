#!/bin/bash

# Post-setup script for Twitch VOD Transcribe devcontainer
echo "🔧 Starting post-setup configuration..."

# Update package lists
echo "📦 Updating package lists..."
apt-get update

# Install system dependencies
echo "🛠️ Installing system dependencies..."
apt-get install -y python3-pip ffmpeg git curl

# Install Python requirements
echo "🐍 Installing Python requirements..."
pip3 install --no-cache-dir -r requirements.txt

# Install additional Python packages
echo "⚡ Installing faster-whisper..."
pip3 install --no-cache-dir faster-whisper

# Final setup messages
echo ""
echo "🚀 Container setup complete!"
echo "💡 Run 'nvidia-smi' to check GPU access."
echo "ℹ️  If GPU not available, faster-whisper will automatically use CPU mode."
echo ""