#!/bin/bash

NAMESPACE="rajesh-app"
USERS=("john" "dave" "admin")
VERBS=("get" "list" "watch" "create" "update" "delete")

for user in "${USERS[@]}"; do
  echo -e "\n🔍 Testing access for user: $user"
  for verb in "${VERBS[@]}"; do
    echo -n "Can $user $verb pods? → "
    kubectl auth can-i $verb pods -n $NAMESPACE --as=$user
  done
  echo "-------------------------------------------"
done
