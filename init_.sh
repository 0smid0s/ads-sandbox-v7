#!/bin/bash

set -e

# Wipe all Docker containers and images
echo "Wiping all Docker containers and images..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi  $(docker images -q) --force   2>/dev/null || true

# Pull images from quay.io
echo "Pulling images from quay.io..."
docker pull quay.io/mylastres0rt05/tor-proxy:latest
docker pull quay.io/mylastres0rt05/thor-session:v1.44
docker pull quay.io/mylastres0rt05/thor-session:v1.43
docker pull quay.io/mylastres0rt05/thor-session:v1.42
docker pull quay.io/mylastres0rt05/thor-session:v1.41
docker pull quay.io/mylastres0rt05/thor-session:v1.40

# Tag for local use
docker tag quay.io/mylastres0rt05/tor-proxy:latest tor-proxy
docker tag quay.io/mylastres0rt05/thor-session:v1.44 thor-session:v1.44
docker tag quay.io/mylastres0rt05/thor-session:v1.43 thor-session:v1.43
docker tag quay.io/mylastres0rt05/thor-session:v1.42 thor-session:v1.42
docker tag quay.io/mylastres0rt05/thor-session:v1.41 thor-session:v1.41
docker tag quay.io/mylastres0rt05/thor-session:v1.40 thor-session:v1.40

# Create shared log directory
mkdir -p ~/thor-logs && touch ~/thor-logs/sessions.log

# Deploy 5 tor-proxy containers
echo "Starting tor-proxy containers..."
docker run -d --name tor-9050 -e SOCKS_PORT=9050 -e CONTROL_PORT=9051 -e API_PORT=5000 -p 9050:9050 -p 5000:5000 tor-proxy
docker run -d --name tor-9052 -e SOCKS_PORT=9052 -e CONTROL_PORT=9053 -e API_PORT=5001 -p 9052:9052 -p 5001:5001 tor-proxy
docker run -d --name tor-9054 -e SOCKS_PORT=9054 -e CONTROL_PORT=9055 -e API_PORT=5002 -p 9054:9054 -p 5002:5002 tor-proxy
docker run -d --name tor-9056 -e SOCKS_PORT=9056 -e CONTROL_PORT=9057 -e API_PORT=5003 -p 9056:9056 -p 5003:5003 tor-proxy
docker run -d --name tor-9058 -e SOCKS_PORT=9058 -e CONTROL_PORT=9059 -e API_PORT=5004 -p 9058:9058 -p 5004:5004 tor-proxy

# Write orchestrator
cat > /usr/local/bin/orchestrator.py << 'EOF'
import subprocess, time, random, os
from concurrent.futures import ThreadPoolExecutor, as_completed

SESSIONS = [
    {"socks_port": 9050, "api_port": 5000, "image": "thor-session:v1.44"},
    {"socks_port": 9052, "api_port": 5001, "image": "thor-session:v1.43"},
    {"socks_port": 9054, "api_port": 5002, "image": "thor-session:v1.42"},
    {"socks_port": 9056, "api_port": 5003, "image": "thor-session:v1.41"},
    {"socks_port": 9058, "api_port": 5004, "image": "thor-session:v1.40"},
]

MAX_RETRIES = 3

def run_session(s, attempt=1):
    port = s["socks_port"]
    name = f"session-{port}-{int(time.time())}"
    cmd = [
        "docker", "run", "--rm", "--name", name, "--network", "host",
        "-e", f"SOCKS_PORT={port}", "-e", f"API_PORT={s['api_port']}",
        "-v", f"{os.path.expanduser('~')}/thor-logs:/logs",
        s["image"], "python", "thor_main.py", "--tor", f"--socks-port={port}",
    ]
    print(f"[{port}] attempt {attempt} → {s['image']}")
    ok = subprocess.run(cmd).returncode == 0
    print(f"[{port}] {'✅ done' if ok else '❌ failed'}")
    return ok

def run_with_retry(s):
    for attempt in range(1, MAX_RETRIES + 1):
        if run_session(s, attempt):
            return
        if attempt < MAX_RETRIES:
            time.sleep(random.uniform(5, 15))
    print(f"[{s['socks_port']}] gave up after {MAX_RETRIES} attempts")

with ThreadPoolExecutor(max_workers=len(SESSIONS)) as ex:
    for f in as_completed([ex.submit(run_with_retry, s) for s in SESSIONS]):
        f.result()
EOF

# Run sessions
echo "Running sessions..."
python3 /usr/local/bin/orchestrator.py
