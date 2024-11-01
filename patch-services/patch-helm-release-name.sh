#!/bin/bash

# Define the prefix to search for in Services
PREFIX="crossplane"

# Get all Services in all namespaces that start with the specified prefix
SERVICES=$(kubectl get svc --all-namespaces -o json | jq -r --arg prefix "$PREFIX" '.items[] | select(.metadata.name | startswith($prefix)) | "\(.metadata.namespace) \(.metadata.name)"')

# Loop through each matching Service
while IFS= read -r line; do
    # Extract namespace and service name
    NAMESPACE=$(echo "$line" | awk '{print $1}')
    SERVICE_NAME=$(echo "$line" | awk '{print $2}')
    
    echo "Processing Service: $SERVICE_NAME in namespace: $NAMESPACE"

    # Check the current release-name annotation
    CURRENT_ANNOTATION=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o json | jq -r '.metadata.annotations["meta.helm.sh/release-name"]')

    if [ "$CURRENT_ANNOTATION" != "crossplane" ]; then
        echo "Updating release-name annotation for Service $SERVICE_NAME in namespace $NAMESPACE"

        # Patch the annotation to change release-name to "crossplane"
        kubectl patch svc "$SERVICE_NAME" -n "$NAMESPACE" --type=json -p='[{"op": "replace", "path": "/metadata/annotations/meta.helm.sh~1release-name", "value": "crossplane"}]'
    else
        echo "No update needed for Service $SERVICE_NAME in namespace $NAMESPACE"
    fi
done <<< "$SERVICES"
