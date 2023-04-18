#!/bin/bash

REGION=$(aws configure get region)


kubectl delete deployment metrics-server -n kube-system
kubectl delete daemonset fluentd-cloudwatch -n amazon-cloudwatch


kubectl delete deployment claudio-deployment -n claudio-namespace
kubectl delete service claudio-service -n claudio-namespace
kubectl delete hpa claudio-hap -n claudio-namespace



aws cloudformation delete-stack --region $REGION --stack-name eks-cluster-managed-nodegroup-stack

if [ $? -ne 0 ]; then
  echo "Failed to delete eks-cluster-managed-nodegroup-stack"
  exit 1
fi


aws cloudformation wait stack-delete-complete --region $REGION --stack-name eks-cluster-managed-nodegroup-stack



aws cloudformation delete-stack --region $REGION --stack-name eks-cluster-stack

if [ $? -ne 0 ]; then
  echo "Failed to delete eks-cluster-stack"
  exit 1
fi

aws cloudformation wait stack-delete-complete --region $REGION --stack-name eks-cluster-stack
