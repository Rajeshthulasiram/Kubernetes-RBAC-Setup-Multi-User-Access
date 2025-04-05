#!/bin/bash

set -e

# Variables
NAMESPACE="rajesh-app"
CLUSTER_NAME="kind-rajesh-cluster"
CONTROL_PLANE="kind-rajesh-cluster-control-plane"

echo "🌀 Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE || true

# Step 1: Create Roles
echo "🔐 Creating Roles..."
kubectl create role read-role \
  --verb=get,list,watch \
  --resource=pods \
  -n $NAMESPACE || true

kubectl create role read-write-role \
  --verb=get,list,watch,create,update \
  --resource=pods \
  -n $NAMESPACE || true

# Step 2: Generate user certificates
echo "📜 Generating certs for john and adam..."
for user in john adam; do
  openssl genrsa -out ${user}.key 2048
  openssl req -new -key ${user}.key -out ${user}.csr -subj "/CN=${user}/O=dev"
done

# Step 3: Copy CA cert and key from Kind control plane
echo "🔑 Copying CA from Kind control plane..."
docker cp $CONTROL_PLANE:/etc/kubernetes/pki/ca.crt .
docker cp $CONTROL_PLANE:/etc/kubernetes/pki/ca.key .

# Step 4: Sign user certs
echo "🖊️ Signing certs..."
for user in john adam; do
  openssl x509 -req -in ${user}.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out ${user}.crt -days 365
done

# Step 5: Add users to kubeconfig
echo "🔧 Adding users to kubeconfig..."
kubectl config set-credentials john \
  --client-certificate=john.crt \
  --client-key=john.key

kubectl config set-credentials adam \
  --client-certificate=adam.crt \
  --client-key=adam.key

# Step 6: Set kubeconfig contexts
echo "🔀 Setting up contexts..."
kubectl config set-context john-context \
  --cluster=$CLUSTER_NAME \
  --namespace=$NAMESPACE \
  --user=john

kubectl config set-context adam-context \
  --cluster=$CLUSTER_NAME \
  --namespace=$NAMESPACE \
  --user=adam

# Step 7: Create RoleBindings
echo "🔗 Creating RoleBindings..."
kubectl create rolebinding john-binding \
  --role=read-role \
  --user=john \
  -n $NAMESPACE || true

kubectl create rolebinding adam-binding \
  --role=read-write-role \
  --user=adam \
  -n $NAMESPACE || true

# Step 8: Deploy test pod
echo "🚀 Deploying test nginx pod..."
kubectl run test-nginx \
  --image=nginx \
  --restart=Never \
  -n $NAMESPACE || true

echo "✅ RBAC setup complete!"
echo "👉 Test using:"
echo "   kubectl config use-context john-context"
echo "   kubectl config use-context adam-context"
