#!/usr/bin/env bash

# install required tools
# make and bash are required to run out docker compose setup
sudo apt-get update -yq && sudo apt-get install -yq \
     ca-certificates \
     curl \
     gnupg \
     lsb-release \
     make \
     bash

# add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# set up the stable repository
echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install Docker Engine
sudo apt-get update -yq && sudo apt-get install -yq \
     docker-ce \
     docker-ce-cli \
     containerd.io
