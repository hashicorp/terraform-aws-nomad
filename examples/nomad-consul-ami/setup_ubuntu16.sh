#!/bin/sh
set -e

SCRIPT=`basename "$0"`

# NOTE: git is required, but it should already be preinstalled on Ubuntu 16.0
#echo "[INFO] [${SCRIPT}] Setup git"
#sudo apt install -y git

# Desired Nomad drivers - Docker and Java
sudo apt install docker.io -y

sudo apt install -y default-jdk
