#!/bin/bash
#https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html


#fix coredns

kubectl patch deployment coredns -n kube-system --type=json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
kubectl rollout restart -n kube-system deployment coredns