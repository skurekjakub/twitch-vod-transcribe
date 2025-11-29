FROM nvidia/cuda:13.0.2-cudnn-runtime-ubuntu24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set timezone to avoid interactive prompts
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    ffmpeg \
    git \
    curl \
    unzip \
    cifs-utils \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install TwitchDownloader CLI
ARG TWITCH_DL_VERSION=1.56.2
RUN cd /tmp && \
    curl -L "https://github.com/lay295/TwitchDownloader/releases/download/${TWITCH_DL_VERSION}/TwitchDownloaderCLI-${TWITCH_DL_VERSION}-Linux-x64.zip" -o TwitchDownloaderCLI.zip && \
    unzip -o TwitchDownloaderCLI.zip && \
    chmod +x TwitchDownloaderCLI && \
    mv TwitchDownloaderCLI /usr/local/bin/ && \
    rm -f TwitchDownloaderCLI.zip COPYRIGHT.txt THIRD-PARTY-LICENSES.txt

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy and install Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Add venv auto-activation to bashrc
RUN echo '\n# Auto-activate Python virtual environment\nsource /opt/venv/bin/activate' >> /root/.bashrc
