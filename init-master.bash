#!/bin/bash
#
# Usage: sudo -E ./init-master.bash [pod_network_type]
#
set -e

# Read Pod Network type from first arg (default to Weave)
POD_NETWORK="${1:-weave}"

POD_NETWORK_CIDR=10.244.0.0/16

# Deploy Kubernetes cluster
kubeadm init --pod-network-cidr=${POD_NETWORK_CIDR}

# By now the master node should be ready!
mkdir -p $HOME/.kube
cp --remove-destination /etc/kubernetes/admin.conf $HOME/.kube/config
chown ${SUDO_UID} -R $HOME/.kube

if [ "$POD_NETWORK" == "flannel" ]; then
	# Install flannel
	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
elif [ "$POD_NETWORK" == "weave" ]; then
	# Install weave
	# From https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
	sysctl net.bridge.bridge-nf-call-iptables=1
	kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=${POD_NETWORK_CIDR}"
else
	echo "Unsupported pod network: $POD_NETWORK"
	echo "Please choose a supported network type from one of the following: flannel weave"
	exit 1
fi

# Make master node a running worker node too!
# FIXME: Use taint tolerations instead in the future
kubectl taint nodes --all node-role.kubernetes.io/master-

# Install Helm 3 (no longer needs Tiller)
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update

# Install NFS provisioner (handled by other script)
# helm install nfs stable/nfs-server-provisioner --namespace=kube-system --set storageClass.defaultClass=true

# STABLE (allegedly), but needs testing
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update

