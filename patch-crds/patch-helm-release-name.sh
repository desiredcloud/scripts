#!/bin/bash

# Define the target CRD groups
CRD_GROUPS=("extern-secrets.io" "generators.external-secrets.io" "abc-secrets.io")

# Loop through each group to find matching CRDs
for group in "${CRD_GROUPS[@]}"; do
    # Get the CRDs matching the group
    CRDS=$(kubectl get crds -o json | jq -r --arg group "$group" '.items[] | select(.spec.group | contains($group)) | .metadata.name')

    for crd in $CRDS; do
        echo "Processing CRD: $crd"

        # Check if the release-name annotation is set to "eso"
        CURRENT_ANNOTATION=$(kubectl get crd "$crd" -o json | jq -r '.metadata.annotations["meta.helm.sh/release-name"]')

        if [ "$CURRENT_ANNOTATION" == "eso" ]; then
            echo "Updating release-name annotation for CRD $crd"

            # Patch the annotation to change release-name to "eso"
            kubectl patch crd "$crd" --type=json -p='[{"op": "replace", "path": "/metadata/annotations/meta.helm.sh~1release-name", "value": "eso"}]'
        else
            echo "No update needed for CRD $crd"
        fi
    done
done
