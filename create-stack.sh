#!/bin/bash

region=$(aws configure get region)



#VPC
#aws cloudformation create-stack --stack-name eks-vpc-stack --template-body file://./eks-vpc.yaml --capabilities CAPABILITY_NAMED_IAM




aws cloudformation create-stack --region $region  --stack-name eks-cluster-stack --template-body file://./eks-ec2-cluster.yaml --capabilities CAPABILITY_NAMED_IAM

result=$?

if [ $result -eq 254 ] || [ $result -eq 255 ]; then
  echo "eks-cluster-stack already exists"
  #exit 0
elif [ $result -ne 0 ]; then
  echo "eks-cluster-stack failed to create " $result
  exit 1
fi

aws cloudformation wait stack-create-complete --region $region --stack-name eks-cluster-stack 

aws eks update-kubeconfig  --name eks-cluster

kubectl get all

aws cloudformation create-stack --region $region --stack-name eks-cluster-managed-nodegroup-stack --template-body file://./eks-ec2-cluster-managed-nodegroup.yaml --capabilities CAPABILITY_NAMED_IAM

result=$?

if [ $result -eq 254 ] || [ $result -eq 255 ]; then
  echo "eks-cluster-managed-nodegroup-stack already exists"
  #exit 0
elif [ $result -ne 0 ]; then
  echo "eks-cluster-managed-nodegroup-stack failed to create " $result
  exit 1
fi


aws cloudformation wait stack-create-complete --region $region --stack-name eks-cluster-managed-nodegroup-stack

kubectl get all