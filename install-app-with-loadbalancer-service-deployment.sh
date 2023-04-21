#!/bin/bash


#****************************************************************************************************************
# Edit configmap with KubeCtlRole to AWS CodeBuild can access 

ROLE="    - rolearn: arn:aws:iam::${ACCOUNT_ID}:role/KubeCtlRole\n      username: build\n      groups:\n        - system:masters"
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"

#****************************************************************************************************************


#************************************************************************************************************
# Install metric server
# https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
#************************************************************************************************************



#************************************************************************************************************
# Install namespace amazon-cloudwatch
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

# Install configmap
kubectl create configmap cluster-info \
--from-literal=cluster.name=eks-cluster \
--from-literal=logs.region=us-west-2 -n amazon-cloudwatch

# Install fluentd daemonset
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluentd/fluentd.yaml


# Display pods for amazon-cloudwatch
kubectl get pods -w --namespace=amazon-cloudwatch
#************************************************************************************************************




#************************************************************************************************************
# Cluster Autoscaler Steps
# https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler
# https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
# Create role with kubectl 
# no IAM OIDC provider associated with cluster, try 'eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=eks-cluster'

# how to create this role from Cloudformation idea:    https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
#aws eks describe-cluster --name <cluster-name> --region <region>
#oidc_id=$(aws eks describe-cluster --name my-cluster --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
#aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
#eksctl utils associate-iam-oidc-provider --cluster my-cluster --approve

eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=eks-cluster --approve
eksctl create iamserviceaccount \
  --cluster=eks-cluster \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::361494667617:policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve

# download cluster-autoscaler-autodiscover.yaml
# curl -O https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
# edited cluster name and other fields
kubectl apply -f cluster-autoscaler-autodiscover-deployment.yaml

kubectl annotate serviceaccount cluster-autoscaler -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::361494667617:role/AmazonEKSClusterAutoscalerRole
#error: --overwrite is false but found the following declared annotation(s): 'eks.amazonaws.com/role-arn' already has a value (arn:aws:iam::361494667617:role/eksctl-eks-cluster-addon-iamserviceaccount-k-Role1-18UJZJJGPRTOE)



kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'

kubectl set image deployment cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.26.2

# View Cluster Autoscaler logs
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler

#to cause cluster autoscale
# 1) node group needs to to have max/min/desired set
# 2) add a deployment with lots of replicas and resources section
#
#apiVersion: apps/v1
#kind: Deployment
#metadata:
#  name: claudio-deployment
#spec:
#  replicas: 20
#  strategy:
#    type: RollingUpdate
#    rollingUpdate:
#      maxUnavailable: 2
#      maxSurge: 2
#    .......
#          resources:
#            requests:
#              cpu: 500m
#              memory: 512Mi
#            limits:
#              cpu: 500m
#              memory: 512Mi

#************************************************************************************************************


#************************************************************************************************************
# Install app
kubectl apply -f app-with-loadbalancer-service-deployment.yaml
#************************************************************************************************************


#************************************************************************************************************
# get all pods
kubectl get pods --all-namespaces 
#kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=ip-192-168-83-155.us-west-2.compute.internal
kubectl get nodes
#************************************************************************************************************

