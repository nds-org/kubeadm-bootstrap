#!/bin/bash

# Wait for instance to finish booting
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# Install Docker + Kubernetes dependencies, add repos
apt-get update  -qq && \
  apt-get update  -qq && \
  apt-get install -qq --no-install-recommends apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
EOF

# Install Docker CE
apt-get update -qq && \
  apt-get update -qq && \
  apt-get install -qq docker-ce docker-ce-cli containerd.io && \
  apt-mark hold docker-ce docker-ce-cli containerd.io

# Configure Docker
systemctl stop docker
modprobe overlay
echo '{"storage-driver": "overlay2"}' > /etc/docker/daemon.json
rm -rf /var/lib/docker/*
systemctl start docker

# Install Kubernetes components
apt-get install -qq kubelet kubeadm kubectl && \
  apt-mark hold kubelet kubeadm kubectl

# Bootstrap system for Kubernetes
cat <<EOF | >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Start up Kubelets
sysctl --system
systemctl daemon-reload
systemctl restart kubelet
