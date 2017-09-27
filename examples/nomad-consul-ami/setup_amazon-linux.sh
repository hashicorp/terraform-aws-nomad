#!/bin/sh
set -e

SCRIPT=`basename "$0"`

echo "[INFO] [${SCRIPT}] Setup git"
sudo yum install -y git

echo "[INFO] [${SCRIPT}] Setup docker"
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
