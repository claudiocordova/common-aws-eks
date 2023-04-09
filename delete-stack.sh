#!/bin/bash

REGION=$(aws configure get region)

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
