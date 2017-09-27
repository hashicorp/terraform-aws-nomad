#!/bin/sh
set -e

SCRIPT=`basename "$0"`

echo "[INFO] [${SCRIPT}] Setup git"
sudo apt install -y git

echo "[INFO] [${SCRIPT}] Setup docker"
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user
