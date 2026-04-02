#!/bin/bash

set -e
  #curl "https://raw.githubusercontent.com/0smid0s/ads-sandbox-v6/refs/heads/main/init_.sh" | sudo sh
REPO_URL="https://github.com/0smid0s/ads-sandbox-v6.git"
DIR_NAME="ads-sandbox*"
DIR_NAME_2="ads-sandbox-v6"

# Wipe all Docker containers and images
echo "Wiping all Docker containers and images..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi  $(docker images -q) --force   2>/dev/null || true

# Remove existing directory
if [ -d "$DIR_NAME" ]; then
    echo "Directory '$DIR_NAME' exists. Removing it..."
    rm -rf "$DIR_NAME"*
fi
# Remove existing directory
if [ -d "$DIR_NAME_2" ]; then
    echo "Directory '$DIR_NAME_2' exists. Removing it..."
    rm -rf "$DIR_NAME_2"
fi
echo "Cloning fresh repository..."
git clone "$REPO_URL"

echo "Entering directory..."
cd "$DIR_NAME_2" || { echo "Failed to enter directory"; exit 1; }

# Build images
echo "Building tor-proxy image..."
cd tor-proxy && docker build -t tor-proxy . && cd ..

# Build 6 thor-session images with different Playwright/Chrome versions
echo "Building thor-session images..."
docker build --build-arg PLAYWRIGHT_TAG=v1.44.0-jammy -t thor-session:v1.44 .
docker build --build-arg PLAYWRIGHT_TAG=v1.43.0-jammy -t thor-session:v1.43 .
docker build --build-arg PLAYWRIGHT_TAG=v1.42.0-jammy -t thor-session:v1.42 .
docker build --build-arg PLAYWRIGHT_TAG=v1.41.0-jammy -t thor-session:v1.41 .
docker build --build-arg PLAYWRIGHT_TAG=v1.40.0-jammy -t thor-session:v1.40 .
docker build --build-arg PLAYWRIGHT_TAG=v1.39.0-jammy -t thor-session:v1.39 .

# Create shared log file
mkdir -p ~/thor-logs && touch ~/thor-logs/sessions.log

# Deploy 6 tor-proxy containers
echo "Starting tor-proxy containers..."
docker run -d --name tor-9050 -e SOCKS_PORT=9050 -e CONTROL_PORT=5000 -p 9050:9050 -p 5000:5000 tor-proxy
docker run -d --name tor-9052 -e SOCKS_PORT=9052 -e CONTROL_PORT=5002 -p 9052:9052 -p 5002:5002 tor-proxy
docker run -d --name tor-9054 -e SOCKS_PORT=9054 -e CONTROL_PORT=5004 -p 9054:9054 -p 5004:5004 tor-proxy
docker run -d --name tor-9056 -e SOCKS_PORT=9056 -e CONTROL_PORT=5006 -p 9056:9056 -p 5006:5006 tor-proxy
docker run -d --name tor-9058 -e SOCKS_PORT=9058 -e CONTROL_PORT=5008 -p 9058:9058 -p 5008:5008 tor-proxy
docker run -d --name tor-9060 -e SOCKS_PORT=9060 -e CONTROL_PORT=5010 -p 9060:9060 -p 5010:5010 tor-proxy

echo "Waiting for Tor to bootstrap..."
sleep 15

# Deploy 6 thor-session containers (each on a different Chrome version)
echo "Starting thor-session containers..."
docker run -d --name session-9050 -e SOCKS_PORT=9050 -e CONTROL_PORT=5000 --network host -v ~/thor-logs:/logs thor-session:v1.44
docker run -d --name session-9052 -e SOCKS_PORT=9052 -e CONTROL_PORT=5002 --network host -v ~/thor-logs:/logs thor-session:v1.43
docker run -d --name session-9054 -e SOCKS_PORT=9054 -e CONTROL_PORT=5004 --network host -v ~/thor-logs:/logs thor-session:v1.42
docker run -d --name session-9056 -e SOCKS_PORT=9056 -e CONTROL_PORT=5006 --network host -v ~/thor-logs:/logs thor-session:v1.41
docker run -d --name session-9058 -e SOCKS_PORT=9058 -e CONTROL_PORT=5008 --network host -v ~/thor-logs:/logs thor-session:v1.40
docker run -d --name session-9060 -e SOCKS_PORT=9060 -e CONTROL_PORT=5010 --network host -v ~/thor-logs:/logs thor-session:v1.39

echo "All containers running. Tailing logs..."
tail -f ~/thor-logs/sessions.log
