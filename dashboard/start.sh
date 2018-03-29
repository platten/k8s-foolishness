#!/bin/bash
set +o
helm install stable/heapster --set rbac.create=true --name heapster --namespace kube-system
helm install stable/kubernetes-dashboard --name dashboard --namespace kube-system --set=rbac.clusterAdminRole=true,serviceAccount.name=dashboard
sleep 15
kubectl apply -f dashboard.yaml
