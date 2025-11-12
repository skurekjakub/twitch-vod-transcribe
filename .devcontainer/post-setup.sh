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

# Check host swap configuration
swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
swap_gb=$((swap_total / 1024 / 1024))
required_gb=32

# Final setup messages
echo ""
echo "🚀 Container setup complete!"
echo "💡 Run 'nvidia-smi' to check GPU access."
echo "ℹ️  If GPU not available, faster-whisper will automatically use CPU mode."
echo ""

if [ "$swap_total" -lt $((required_gb * 1024 * 1024)) ]; then
    echo "⚠️  WARNING: Host swap is ${swap_gb}GB (requires ${required_gb}GB+)"
    echo "⚠️  Large model transcription may fail or cause OOM errors."
    echo "⚠️  To fix, run on your HOST machine (not in container):"
    echo ""
    echo "    sudo fallocate -l 32G /swapfile"
    echo "    sudo chmod 600 /swapfile"
    echo "    sudo mkswap /swapfile"
    echo "    sudo swapon /swapfile"
    echo "    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab"
    echo ""
else
    echo "✅ Host swap: ${swap_gb}GB (sufficient)"
fi
echo ""