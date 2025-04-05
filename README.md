# Kubernetes-RBAC-Setup-Multi-User-Access

# Create Folder for Everything
mkdir -p kind-users/certs
cd kind-users

✅ STEP 1: Create Namespace
kubectl create namespace rajesh-app

✅ STEP 2: Create Roles
🔹 Read-Only Role
  kubectl create role read-role \
  --verb=get,list,watch \
  --resource=pods \
  -n rajesh-app
  
🔹 Read-Write Role
  kubectl create role read-write-role \
  --verb=get,list,watch,create,update \
  --resource=pods \
  -n rajesh-app

✅ STEP 3: Generate User Certificates
🔐 Create Keys & CSRs
 # For john
openssl genrsa -out john.key 2048
openssl req -new -key john.key -out john.csr -subj "/CN=john/O=dev"

# For adam
openssl genrsa -out adam.key 2048
openssl req -new -key adam.key -out adam.csr -subj "/CN=adam/O=dev"

✅ STEP 4: Sign CSRs with Kubernetes CA
🐳 If using kind, copy CA cert & key from control plane:
docker cp rajesh-cluster-control-plan:/etc/kubernetes/pki/ca.crt 
docker cp rajesh-cluster-control-plan:/etc/kubernetes/pki/ca.key

🔏 Sign Certificates
# Sign for john
openssl x509 -req -in john.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out john.crt -days 365

# Sign for adam
openssl x509 -req -in adam.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out adam.crt -days 365

✅ STEP 5: Create User Credentials in Kubeconfig
# john
kubectl config set-credentials john \
  --client-certificate=john.crt \
  --client-key=john.key

# adam
kubectl config set-credentials adam \
  --client-certificate=adam.crt \
  --client-key=adam.key

✅ STEP 6: Create Contexts for Each User
# Replace <CLUSTER_NAME> with your actual kind cluster name if needed
kubectl config set-context john-context \
  --cluster=kind-rajesh-cluster-control-plan \
  --namespace=rajesh-app \
  --user=john

kubectl config set-context adam-context \
  --cluster=kind-rajesh-cluster-control-plan \
  --namespace=rajesh-app \
  --user=adam
  
✅ STEP 7: Bind Roles to Users
🔗 john → read-role
kubectl create rolebinding john-binding \
  --role=read-role \
  --user=john \
  -n rajesh-app

🔗 adam → read-write-role
kubectl create rolebinding adam-binding \
  --role=read-write-role \
  --user=adam \
  -n rajesh-app

✅ STEP 8: Deploy Test Pod
kubectl run test-nginx \
  --image=nginx \
  --restart=Never \
  -n rajesh-app

✅ STEP 9: Test Access for Each User
🧪 Switch to john
kubectl config use-context john-context
kubectl get pods -n rajesh-app    # ✅ should work
kubectl delete pod test-nginx     # ❌ should be forbidden

🧪 Switch to adam
kubectl config use-context adam-context
kubectl get pods -n rajesh-app    # ✅
kubectl delete pod test-nginx     # ✅






