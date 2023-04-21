#!/bin/bash
#https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html



#****************************************************************************************************************
# Edit configmap with KubeCtlRole to AWS CodeBuild can access or edit manaully 
# kubectl edit -n kube-system configmap/aws-auth

ROLE="    - rolearn: arn:aws:iam::361494667617:role/KubeCtlRole\n      username: build\n      groups:\n        - system:masters"
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"

#****************************************************************************************************************



#****************************************************************************************************************
#https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
#Creating an IAM OIDC provider for your cluster
#oidc_id=$(aws eks describe-cluster --name eks-cluster --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
#aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4=
#if no output returned
#Claudios-MBP:poker-hand-analyzer-microservice-springboot-aws-eks claudiocordova$ aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4=
#cut: [-bcf] list: illegal list value



eksctl utils associate-iam-oidc-provider --cluster eks-cluster --approve
#****************************************************************************************************************

#****************************************************************************************************************
#https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html#boundserviceaccounttoken-validated-add-on-versions
# update add-ons versions

#****************************************************************************************************************
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster=eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::361494667617:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

eksctl get iamserviceaccount --cluster eks-cluster --name aws-load-balancer-controller --namespace kube-system

helm repo add eks https://aws.github.io/eks-charts
helm repo update

#https://repost.aws/knowledge-center/eks-alb-ingress-controller-fargate
#do i need this?
#kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-west-2 \
  --set vpcId=vpc-040672d20e7f42be7--- -- - - - 


kubectl get deployment -n kube-system aws-load-balancer-controller

#****************************************************************************************************************



#************************************************************************************************************
# Install app
kubectl apply -f app-with-nodeport-service-deployment.yaml


kubectl get all -n claudio-namespace

# Install ingress
kubectl apply -f app-ingress.yaml

#logs
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller
kubectl get all -n claudio-namespace
kubectl get ingress  -n claudio-namespace

#************************************************************************************************************



