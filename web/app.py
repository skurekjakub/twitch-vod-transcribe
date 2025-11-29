"""
VOD Transcriber Web Interface
Simple FastAPI app for managing download/transcription queues
"""

import os
import subprocess
from pathlib import Path
from datetime import datetime

from fastapi import FastAPI, HTTPException, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

# Paths
ROOT_DIR = Path(__file__).parent.parent
URLS_VODS = ROOT_DIR / "urls-vods"
URLS_VODS_PROCESSED = ROOT_DIR / "urls-vods-processed"
URLS_TXT = ROOT_DIR / "urls.txt"
LOGS_DIR = ROOT_DIR / "logs"

app = FastAPI(title="VOD Transcriber")


class URLItem(BaseModel):
    url: str
    prefix: str = ""


class QueueType(BaseModel):
    queue: str  # "download" or "transcribe"


# --- Helpers ---

def read_queue(file_path: Path) -> list[dict]:
    """Read URLs from a queue file, returning list of {url, prefix, is_comment}"""
    if not file_path.exists():
        return []
    
    items = []
    for line in file_path.read_text().strip().split("\n"):
        if not line.strip():
            continue
        if line.strip().startswith("#"):
            items.append({"url": line, "prefix": "", "is_comment": True})
        else:
            parts = line.split(maxsplit=1)
            url = parts[0]
            prefix = parts[1] if len(parts) > 1 else ""
            items.append({"url": url, "prefix": prefix, "is_comment": False})
    return items


def write_queue(file_path: Path, items: list[dict]):
    """Write items back to queue file"""
    lines = []
    for item in items:
        if item.get("is_comment"):
            lines.append(item["url"])
        elif item.get("prefix"):
            lines.append(f"{item['url']} {item['prefix']}")
        else:
            lines.append(item["url"])
    file_path.write_text("\n".join(lines) + "\n" if lines else "")


def get_status() -> dict:
    """Get system status"""
    # NAS check
    nas_mounted = os.path.ismount("/nas") or "nas" in subprocess.run(
        ["grep", "-s", " /nas ", "/proc/mounts"], 
        capture_output=True, text=True
    ).stdout
    
    # GPU check
    gpu_available = False
    gpu_info = ""
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,memory.used,memory.total", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            gpu_available = True
            gpu_info = result.stdout.strip()
    except:
        pass
    
    return {
        "nas_mounted": bool(nas_mounted),
        "gpu_available": gpu_available,
        "gpu_info": gpu_info,
        "download_queue_count": len([i for i in read_queue(URLS_VODS) if not i.get("is_comment")]),
        "transcribe_queue_count": len([i for i in read_queue(URLS_TXT) if not i.get("is_comment")]),
    }


# --- API Routes ---

@app.get("/api/status")
def api_status():
    """Get system status"""
    return get_status()


@app.get("/api/queue/{queue_type}")
def api_get_queue(queue_type: str):
    """Get queue contents"""
    if queue_type == "download":
        return {"queue": "download", "items": read_queue(URLS_VODS)}
    elif queue_type == "transcribe":
        return {"queue": "transcribe", "items": read_queue(URLS_TXT)}
    else:
        raise HTTPException(400, "Invalid queue type. Use 'download' or 'transcribe'")


@app.post("/api/queue/{queue_type}/add")
def api_add_to_queue(queue_type: str, item: URLItem):
    """Add URL to queue"""
    if queue_type == "download":
        file_path = URLS_VODS
    elif queue_type == "transcribe":
        file_path = URLS_TXT
    else:
        raise HTTPException(400, "Invalid queue type")
    
    items = read_queue(file_path)
    items.append({"url": item.url, "prefix": item.prefix, "is_comment": False})
    write_queue(file_path, items)
    
    return {"status": "ok", "message": f"Added to {queue_type} queue"}


@app.delete("/api/queue/{queue_type}/remove")
def api_remove_from_queue(queue_type: str, item: URLItem):
    """Remove URL from queue"""
    if queue_type == "download":
        file_path = URLS_VODS
    elif queue_type == "transcribe":
        file_path = URLS_TXT
    else:
        raise HTTPException(400, "Invalid queue type")
    
    items = read_queue(file_path)
    items = [i for i in items if i["url"] != item.url]
    write_queue(file_path, items)
    
    return {"status": "ok", "message": f"Removed from {queue_type} queue"}


@app.get("/api/processed")
def api_get_processed():
    """Get recently processed URLs"""
    return {"items": read_queue(URLS_VODS_PROCESSED)[:20]}


@app.get("/api/logs")
def api_get_logs():
    """Get list of recent log files"""
    if not LOGS_DIR.exists():
        return {"logs": []}
    
    logs = sorted(LOGS_DIR.glob("*.log"), key=lambda x: x.stat().st_mtime, reverse=True)[:10]
    return {"logs": [{"name": l.name, "size": l.stat().st_size, "modified": l.stat().st_mtime} for l in logs]}


@app.get("/api/logs/{filename}")
def api_get_log_content(filename: str):
    """Get log file content (last 100 lines)"""
    log_file = LOGS_DIR / filename
    if not log_file.exists() or not log_file.is_file():
        raise HTTPException(404, "Log file not found")
    
    lines = log_file.read_text().strip().split("\n")
    return {"filename": filename, "lines": lines[-100:]}


# --- HTML UI ---

@app.get("/", response_class=HTMLResponse)
def index():
    """Main UI"""
    return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VOD Transcriber</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
            background: #1a1a2e;
            color: #eee;
        }
        h1 { color: #9d4edd; margin-bottom: 5px; }
        h2 { color: #7b2cbf; border-bottom: 1px solid #333; padding-bottom: 10px; }
        .subtitle { color: #888; margin-bottom: 30px; }
        
        .status-bar {
            display: flex;
            gap: 20px;
            margin-bottom: 30px;
            padding: 15px;
            background: #16213e;
            border-radius: 8px;
        }
        .status-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }
        .status-dot.ok { background: #4ade80; }
        .status-dot.error { background: #f87171; }
        
        .queue-section { margin-bottom: 40px; }
        
        .add-form {
            display: flex;
            gap: 10px;
            margin-bottom: 15px;
        }
        .add-form input[type="text"] {
            flex: 1;
            padding: 10px 15px;
            border: 1px solid #333;
            border-radius: 6px;
            background: #0f0f23;
            color: #eee;
            font-size: 14px;
        }
        .add-form input[type="text"]:focus {
            outline: none;
            border-color: #9d4edd;
        }
        .add-form input[name="prefix"] {
            max-width: 150px;
        }
        
        button {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.2s;
        }
        .btn-primary {
            background: #9d4edd;
            color: white;
        }
        .btn-primary:hover { background: #7b2cbf; }
        .btn-danger {
            background: #dc2626;
            color: white;
            padding: 5px 10px;
            font-size: 12px;
        }
        .btn-danger:hover { background: #b91c1c; }
        
        .queue-list {
            background: #16213e;
            border-radius: 8px;
            overflow: hidden;
        }
        .queue-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 15px;
            border-bottom: 1px solid #1a1a2e;
        }
        .queue-item:last-child { border-bottom: none; }
        .queue-item.comment {
            color: #666;
            font-style: italic;
        }
        .queue-url {
            font-family: monospace;
            font-size: 13px;
            word-break: break-all;
        }
        .queue-prefix {
            color: #9d4edd;
            margin-left: 10px;
            font-size: 12px;
        }
        .queue-empty {
            padding: 20px;
            text-align: center;
            color: #666;
        }
        
        .tabs {
            display: flex;
            gap: 5px;
            margin-bottom: 20px;
        }
        .tab {
            padding: 10px 20px;
            background: #16213e;
            border: none;
            border-radius: 6px 6px 0 0;
            color: #888;
            cursor: pointer;
        }
        .tab.active {
            background: #9d4edd;
            color: white;
        }
        
        .badge {
            background: #9d4edd;
            color: white;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 12px;
            margin-left: 8px;
        }
    </style>
</head>
<body>
    <h1>📼 VOD Transcriber</h1>
    <p class="subtitle">Download & transcribe Twitch VODs and YouTube videos</p>
    
    <div class="status-bar" id="status-bar">
        <div class="status-item">
            <span class="status-dot" id="nas-status"></span>
            <span>NAS</span>
        </div>
        <div class="status-item">
            <span class="status-dot" id="gpu-status"></span>
            <span id="gpu-info">GPU</span>
        </div>
    </div>
    
    <div class="tabs">
        <button class="tab active" onclick="showTab('download')">
            Downloads <span class="badge" id="download-count">0</span>
        </button>
        <button class="tab" onclick="showTab('transcribe')">
            Transcribe <span class="badge" id="transcribe-count">0</span>
        </button>
    </div>
    
    <div id="download-tab" class="queue-section">
        <form class="add-form" onsubmit="addToQueue(event, 'download')">
            <input type="text" name="url" placeholder="https://www.youtube.com/watch?v=... or Twitch URL" required>
            <input type="text" name="prefix" placeholder="prefix (optional)">
            <button type="submit" class="btn-primary">Add</button>
        </form>
        <div class="queue-list" id="download-queue"></div>
    </div>
    
    <div id="transcribe-tab" class="queue-section" style="display: none;">
        <form class="add-form" onsubmit="addToQueue(event, 'transcribe')">
            <input type="text" name="url" placeholder="https://www.youtube.com/watch?v=... or Twitch URL" required>
            <input type="text" name="prefix" placeholder="prefix (optional)">
            <button type="submit" class="btn-primary">Add</button>
        </form>
        <div class="queue-list" id="transcribe-queue"></div>
    </div>

    <script>
        let currentTab = 'download';
        
        function showTab(tab) {
            currentTab = tab;
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelector(`.tab[onclick="showTab('${tab}')"]`).classList.add('active');
            document.getElementById('download-tab').style.display = tab === 'download' ? 'block' : 'none';
            document.getElementById('transcribe-tab').style.display = tab === 'transcribe' ? 'block' : 'none';
        }
        
        async function loadStatus() {
            const res = await fetch('/api/status');
            const data = await res.json();
            
            document.getElementById('nas-status').className = 'status-dot ' + (data.nas_mounted ? 'ok' : 'error');
            document.getElementById('gpu-status').className = 'status-dot ' + (data.gpu_available ? 'ok' : 'error');
            document.getElementById('gpu-info').textContent = data.gpu_info || 'GPU';
            document.getElementById('download-count').textContent = data.download_queue_count;
            document.getElementById('transcribe-count').textContent = data.transcribe_queue_count;
        }
        
        async function loadQueue(queueType) {
            const res = await fetch(`/api/queue/${queueType}`);
            const data = await res.json();
            
            const container = document.getElementById(`${queueType}-queue`);
            if (data.items.length === 0) {
                container.innerHTML = '<div class="queue-empty">Queue is empty</div>';
                return;
            }
            
            container.innerHTML = data.items.map(item => {
                if (item.is_comment) {
                    return `<div class="queue-item comment">${item.url}</div>`;
                }
                return `
                    <div class="queue-item">
                        <div>
                            <span class="queue-url">${item.url}</span>
                            ${item.prefix ? `<span class="queue-prefix">${item.prefix}</span>` : ''}
                        </div>
                        <button class="btn-danger" onclick="removeFromQueue('${queueType}', '${item.url}')">Remove</button>
                    </div>
                `;
            }).join('');
        }
        
        async function addToQueue(event, queueType) {
            event.preventDefault();
            const form = event.target;
            const url = form.url.value.trim();
            const prefix = form.prefix.value.trim();
            
            await fetch(`/api/queue/${queueType}/add`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url, prefix })
            });
            
            form.reset();
            loadQueue(queueType);
            loadStatus();
        }
        
        async function removeFromQueue(queueType, url) {
            await fetch(`/api/queue/${queueType}/remove`, {
                method: 'DELETE',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url })
            });
            
            loadQueue(queueType);
            loadStatus();
        }
        
        // Initial load
        loadStatus();
        loadQueue('download');
        loadQueue('transcribe');
        
        // Refresh every 30s
        setInterval(() => {
            loadStatus();
            loadQueue(currentTab);
        }, 30000);
    </script>
</body>
</html>
"""


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
