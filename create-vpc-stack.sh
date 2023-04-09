#!/bin/bash

region=$(aws configure get region)



#VPC
aws cloudformation create-stack --stack-name eks-vpc-stack --template-body file://./eks-vpc.yaml --capabilities CAPABILITY_NAMED_IAM

result=$?

aws cloudformation wait stack-create-complete --region $region --stack-name eks-vpc-stack

if [ $result -eq 254 ] || [ $result -eq 255 ]; then
  echo "eks-vpc-stack already exists"
  #exit 0
elif [ $result -ne 0 ]; then
  echo "eks-vpc-stack failed to create " $result
  exit 1
fi

