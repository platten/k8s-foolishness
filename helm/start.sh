#!/bin/bash
set +o
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
kubectl create -f  rbac-config.yaml
helm init --service-account tiller
