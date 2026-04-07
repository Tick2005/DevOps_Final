#!/bin/bash

# Script to view logs from pods

NAMESPACE="devops-final"

echo "=========================================="
echo "Pod Logs Viewer"
echo "=========================================="

# Check if app name is provided
if [ -z "$1" ]; then
    echo "Usage: ./logs.sh [backend|frontend]"
    echo ""
    echo "Available pods:"
    kubectl get pods -n $NAMESPACE
    exit 1
fi

APP=$1

# Get the first pod for the app
POD=$(kubectl get pods -n $NAMESPACE -l app=$APP -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "No pods found for app: $APP"
    exit 1
fi

echo "Showing logs for: $POD"
echo "=========================================="
kubectl logs -f $POD -n $NAMESPACE
