#!/bin/bash

# ==============================================================================
# Script Name: create-rhoai-connection-v2.sh
# Description: Creates a fully UI-visible S3 Data Connection for RHOAI 3.x
#              Now includes the critical 'connection-type' linkage.
# Usage:       ./create-rhoai-connection-v2.sh <project-name> <connection-name>
# ==============================================================================


if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <project-name> <connection-name>"
    exit 1
fi

PROJECT_NAME=$1
CONNECTION_NAME=$2

# --- CONFIGURATION ---
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minio}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minio123}"
AWS_S3_ENDPOINT="${AWS_S3_ENDPOINT:-http://minio-service.$PROJECT_NAME.svc.cluster.local:9000}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
AWS_S3_BUCKET="${AWS_S3_BUCKET:-private-models}"
# ---------------------

echo "Creating UI-Visible Data Connection '$CONNECTION_NAME'..."

cat <<EOF | oc apply -n "$PROJECT_NAME" -f -
apiVersion: v1
kind: Secret
metadata:
  name: $CONNECTION_NAME
  labels:
    opendatahub.io/dashboard: "true"
    opendatahub.io/managed: "true" # <-- ADDED: 3.3 UI Visibility Requirement
  annotations:
    opendatahub.io/connection-type: "s3"
    opendatahub.io/connection-type-protocol: "s3" # <-- ADDED: 3.3 Backend Routing Requirement
    openshift.io/display-name: "private-models"
    openshift.io/description: "Read-only access to the corporate data lake."
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: "$AWS_ACCESS_KEY_ID"
  AWS_SECRET_ACCESS_KEY: "$AWS_SECRET_ACCESS_KEY"
  AWS_S3_ENDPOINT: "$AWS_S3_ENDPOINT"
  AWS_DEFAULT_REGION: "$AWS_DEFAULT_REGION"
  AWS_S3_BUCKET: "$AWS_S3_BUCKET"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Success! Connection '$CONNECTION_NAME' created and linked to type 's3'."
else
    echo "❌ Error creating connection."
fi
