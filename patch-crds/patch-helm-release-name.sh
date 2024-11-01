#!/bin/bash

# Define the groups to search for
CRD_GROUPS=("extern-secrets.io" "generators.external-secrets.io" "abc-secrets.io")

# Loop through each group to find matching CRDs
for group in "${CRD_GROUPS[@]}"; do
    # Get the CRDs matching the group
    CRDS=$(kubectl get crds -o json | jq -r --arg group "$group" '.items[] | select(.spec.group | contains($group)) | .metadata.name')

    for crd in $CRDS; do
        echo "Processing CRD: $crd"

        # Get all resources of this CRD type
        RESOURCES=$(kubectl get "$crd" --all-namespaces -o json | jq -c '.items[]')

        for resource in $RESOURCES; do
            # Extract the namespace and name
            NAMESPACE=$(echo "$resource" | jq -r '.metadata.namespace')
            NAME=$(echo "$resource" | jq -r '.metadata.name')

            # Check if the release-name annotation is set to "vcontrolplane"
            CURRENT_ANNOTATION=$(echo "$resource" | jq -r '.metadata.annotations["meta.helm.sh/release-name"]')

            if [ "$CURRENT_ANNOTATION" == "vcontrolplane" ]; then
                echo "Updating release-name annotation for $crd/$NAME in namespace $NAMESPACE"

                # Patch the annotation to change release-name to "vcontrolplane-eso"
                kubectl annotate "$crd" "$NAME" -n "$NAMESPACE" "meta.helm.sh/release-name=vcontrolplane-eso" --overwrite
            else
                echo "No update needed for $crd/$NAME in namespace $NAMESPACE"
            fi
        done
    done
done
