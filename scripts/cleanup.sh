#!/bin/bash
set -e

echo "=== Cleanup Script ==="
echo ""
echo "This will delete all StartupX resources from the cluster."
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Deleting all resources in startupx namespace..."
kubectl delete namespace startupx --grace-period=30

echo "Deleting cluster-wide resources..."
kubectl delete clusterissuer letsencrypt-prod letsencrypt-staging --ignore-not-found=true
kubectl delete clusterrole prometheus --ignore-not-found=true
kubectl delete clusterrolebinding prometheus --ignore-not-found=true

echo ""
echo "Cleanup complete!"
