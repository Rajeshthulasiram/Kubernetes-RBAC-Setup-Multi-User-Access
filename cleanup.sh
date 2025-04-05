#!/bin/bash

set -e

# Variables
NAMESPACE="rajesh-app"
CLUSTER_NAME="kind-rajesh-cluster"
CONTROL_PLANE="kind-rajesh-cluster-control-plane"

echo "🔥 Deleting test pod..."
kubectl delete pod test-nginx -n $NAMESPACE --ignore-not-found

echo "🔗 Deleting RoleBindings..."
kubectl delete rolebinding john-binding -n $NAMESPACE --ignore-not-found
kubectl delete rolebinding adam-binding -n $NAMESPACE --ignore-not-found

echo "🔐 Deleting Roles..."
kubectl delete role read-role -n $NAMESPACE --ignore-not-found
kubectl delete role read-write-role -n $NAMESPACE --ignore-not-found

echo "🗑️ Deleting Namespace..."
kubectl delete namespace $NAMESPACE --ignore-not-found

echo "⚙️ Cleaning up Kubeconfig entries..."
kubectl config delete-context john-context 2>/dev/null || true
kubectl config delete-context adam-context 2>/dev/null || true
kubectl config delete-user john 2>/dev/null || true
kubectl config delete-user adam 2>/dev/null || true

echo "🧼 Deleting generated certs and keys..."
rm -f john.key john.csr john.crt
rm -f adam.key adam.csr adam.crt
rm -f ca.crt ca.key ca.srl

echo "📦 (Optional) To delete the Kind cluster:"
echo "    kind delete cluster --name rajesh-cluster"

echo "✅ Cleanup completed successfully!"
