# DevContainer for Twitch VOD Transcribe

This devcontainer provides a CUDA-enabled environment with all dependencies pre-installed.

## Prerequisites

1. **Docker** with NVIDIA GPU support
2. **NVIDIA Container Toolkit** installed on your host
3. **VS Code** with the "Dev Containers" extension

## Setup NVIDIA Docker (if not already done)

```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

## Usage

1. Open this folder in VS Code
2. Press `F1` and select "Dev Containers: Reopen in Container"
3. Wait for the container to build and dependencies to install
4. Your Hugging Face cache will be mounted from `~/.cache/huggingface` to preserve downloaded models

## What's Included

- NVIDIA CUDA 12.3.2
- cuDNN 9
- Python 3 with pip
- FFmpeg for audio processing
- All Python dependencies from `requirements.txt`
- faster-whisper with GPU acceleration

## Testing GPU Access

Inside the container, run:
```bash
nvidia-smi
```

You should see your GPU listed!
