#!/usr/bin/env python3
"""
Download Twitch VOD using twitch-dl
Usage: python download_vod.py <twitch_vod_url>
Example: python download_vod.py https://www.twitch.tv/videos/738103227
"""

import sys
import subprocess
import re
import os

def extract_vod_id(url):
    """Extract VOD ID from Twitch URL"""
    match = re.search(r'/videos/(\d+)', url)
    if match:
        return match.group(1)
    return None

def download_vod(vod_url):
    """Download VOD using twitch-dl"""
    vod_id = extract_vod_id(vod_url)
    
    if not vod_id:
        print(f"Error: Could not extract VOD ID from URL: {vod_url}")
        print("Expected format: https://www.twitch.tv/videos/XXXXXXXX")
        return False
    
    print(f"VOD ID: {vod_id}")
    print(f"Downloading VOD from: {vod_url}")
    print("-" * 60)
    
    try:
        # Download the VOD using twitch-dl
        # -q 480p = download at 480p (sufficient for audio extraction)
        # -o = output filename pattern
        output_pattern = f"{vod_id}.mp4"
        
        cmd = ["twitch-dl", "download", "-q", "480p", vod_url]
        
        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd, check=True)
        
        print("-" * 60)
        print(f"✓ Download complete!")
        print(f"✓ Video saved with VOD ID: {vod_id}")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error downloading VOD: {e}")
        return False
    except FileNotFoundError:
        print("Error: twitch-dl not found. Please install it with: pip install twitch-dl")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python download_vod.py <twitch_vod_url>")
        print("Example: python download_vod.py https://www.twitch.tv/videos/738103227")
        sys.exit(1)
    
    vod_url = sys.argv[1]
    
    success = download_vod(vod_url)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
