#!/bin/bash

# Define the prefix to search for in ClusterRoles
PREFIX="eso"

# Get all ClusterRoles that start with the specified prefix
CLUSTERROLES=$(kubectl get clusterrole -o json | jq -r --arg prefix "$PREFIX" '.items[] | select(.metadata.name | startswith($prefix)) | .metadata.name')

# Loop through each matching ClusterRole
for role in $CLUSTERROLES; do
    echo "Processing ClusterRole: $role"

    # Check the current release-name annotation
    CURRENT_ANNOTATION=$(kubectl get clusterrole "$role" -o json | jq -r '.metadata.annotations["meta.helm.sh/release-name"]')

    if [ "$CURRENT_ANNOTATION" != "eso" ]; then
        echo "Updating release-name annotation for ClusterRole $role"

        # Patch the annotation to change release-name to "eso"
        kubectl patch clusterrole "$role" --type=json -p='[{"op": "replace", "path": "/metadata/annotations/meta.helm.sh~1release-name", "value": "eso"}]'
    else
        echo "No update needed for ClusterRole $role"
    fi
done
