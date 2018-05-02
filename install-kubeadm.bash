#!/bin/bash
apt-get update
apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
EOF

apt-get update

apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial

COMMON_DOCKER_PROPS='"storage-driver": "overlay2"'

# See if a docker volume device was provided
if [ "$#" = 1 ]; then
  mkfs -t ext3 $1
  mkdir /opt/docker
  mount $1 /opt/docker
  DOCKER_VOL_PROPS='"graph":"/opt/docker"'
fi

systemctl stop docker
modprobe overlay

if [ "$DOCKER_VOL_PROPS" ] ; then
  echo "{$COMMON_DOCKER_PROPS, $DOCKER_VOL_PROPS}" > /etc/docker/daemon.json
else
  echo "{$COMMON_DOCKER_PROPS}" > /etc/docker/daemon.json
fi
rm -rf /var/lib/docker/*
systemctl start docker

# Install kubernetes components!
apt-get install -y \
        kubelet=1.9.2-00 \
        kubeadm=1.9.2-00 \
        kubernetes-cni=0.6.0-00
