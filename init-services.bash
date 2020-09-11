#!/bin/bash
# 
# Usage: sudo -E./init-services.bash [pod_network_type]
#

helm install ingress nginx-stable/nginx-ingress --namespace=kube-system -f support/values.yaml

# DEPRECATED, but working
#helm install ingress stable/nginx-ingress --namespace=kube-system -f support/values.yaml
