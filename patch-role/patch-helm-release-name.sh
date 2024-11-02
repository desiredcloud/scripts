#!/bin/bash

# Define the prefix to search for in Roles
PREFIX="-kyverno"

# Get all Roles in all namespaces that start with the specified prefix
ROLES=$(kubectl get role --all-namespaces -o json | jq -r --arg prefix "$PREFIX" '.items[] | select(.metadata.name | startswith($prefix)) | "\(.metadata.namespace) \(.metadata.name)"')

# Loop through each matching Role
while IFS= read -r line; do
    # Extract namespace and role name
    NAMESPACE=$(echo "$line" | awk '{print $1}')
    ROLE_NAME=$(echo "$line" | awk '{print $2}')
    
    echo "Processing Role: $ROLE_NAME in namespace: $NAMESPACE"

    # Check the current release-name annotation
    CURRENT_ANNOTATION=$(kubectl get role "$ROLE_NAME" -n "$NAMESPACE" -o json | jq -r '.metadata.annotations["meta.helm.sh/release-name"]')

    if [ "$CURRENT_ANNOTATION" != "-kyverno" ]; then
        echo "Updating release-name annotation for Role $ROLE_NAME in namespace $NAMESPACE"

        # Patch the annotation to change release-name to "-kyverno"
        kubectl patch role "$ROLE_NAME" -n "$NAMESPACE" --type=json -p='[{"op": "replace", "path": "/metadata/annotations/meta.helm.sh~1release-name", "value": "-kyverno"}]'
    else
        echo "No update needed for Role $ROLE_NAME in namespace $NAMESPACE"
    fi
done <<< "$ROLES"
