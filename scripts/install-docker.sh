#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[1/5] Updating package index..."
apt-get update -y

echo "[2/5] Installing dependencies..."
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

echo "[3/5] Installing Docker..."
apt-get install -y docker.io

echo "[4/5] Enabling Docker service..."
systemctl enable docker
systemctl start docker

echo "[5/5] Configuring vagrant user..."
usermod -aG docker vagrant

docker --version
systemctl is-active --quiet docker

echo
echo "Docker installation completed successfully."
echo
echo "Note:"
echo "Membership in the docker group allows Docker usage without sudo,"
echo "but grants privileges equivalent to root on the host."