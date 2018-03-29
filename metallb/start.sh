#!/bin/bash
set +o

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.4.6/manifests/metallb.yaml
kubectl create -f metallb-config.yaml
