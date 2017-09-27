#!/bin/sh
set -e

SCRIPT=`basename "$0"`

# NOTE: git is already preinstalled
#echo "[INFO] [${SCRIPT}] Setup git"
#sudo apt install -y git

# Using Docker CE directly provided by Docker
echo "[INFO] [${SCRIPT}] Setup docker"
cd /tmp/
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce

sudo apt-get install -y docker-ce
sudo usermod -a -G docker ubuntu

# Make is needed for the AWS ECR Helper - FIXME: should be removed after setup
echo "[INFO] [${SCRIPT}] Setup make"
sudo apt-get install make
