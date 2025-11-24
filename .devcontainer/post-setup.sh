#!/bin/bash

# Post-setup script for Twitch VOD Transcribe devcontainer
echo "🔧 Starting post-setup configuration..."

# Update package lists
echo "📦 Updating package lists..."
apt-get update

# Install system dependencies
echo "🛠️ Installing system dependencies..."
apt-get install -y python3-pip python3-venv ffmpeg git curl unzip cifs-utils

# Set up Python virtual environment
echo "🐍 Setting up Python virtual environment..."
cd /workspaces/twitch-vod-transcribe
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate

# Install Python requirements
echo "🐍 Installing Python requirements..."
pip install --upgrade pip
pip install --no-cache-dir -r requirements.txt

# Install TwitchDownloader CLI
echo "📥 Installing TwitchDownloader CLI..."
TWITCH_DL_VERSION="1.56.2"
TWITCH_DL_URL="https://github.com/lay295/TwitchDownloader/releases/download/${TWITCH_DL_VERSION}/TwitchDownloaderCLI-${TWITCH_DL_VERSION}-Linux-x64.zip"
cd /tmp
curl -L "$TWITCH_DL_URL" -o TwitchDownloaderCLI.zip
unzip -o TwitchDownloaderCLI.zip
chmod +x TwitchDownloaderCLI
mv TwitchDownloaderCLI /usr/local/bin/
rm -f TwitchDownloaderCLI.zip COPYRIGHT.txt THIRD-PARTY-LICENSES.txt
cd -
echo "✅ TwitchDownloader CLI installed: $(TwitchDownloaderCLI --version 2>&1 | head -1)"

# Mount NAS
.devcontainer/mount-nas.sh

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

# Add venv auto-activation to bashrc
echo "🔄 Configuring automatic venv activation..."
cat >> /root/.bashrc << 'EOF'

# Auto-activate Python virtual environment
if [ -f /workspaces/twitch-vod-transcribe/.venv/bin/activate ]; then
    source /workspaces/twitch-vod-transcribe/.venv/bin/activate
fi
EOF
echo "✅ Virtual environment will auto-activate on shell startup"