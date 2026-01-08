#!/bin/bash

# =================================================================================
# SCRIPT: setup.sh
# DESCRIPTION: Automates the "Plumbing" phase of the Model Registry QuickStart.
#              1. Creates the Namespace
#              2. Deploys MinIO (Object Storage)
#              3. Deploys MySQL (Metadata Storage)
#              4. Creates Connection Secrets for the Registry Operator
# =================================================================================

set -e # Exit immediately if a command exits with a non-zero status

# Configuration Variables
NAMESPACE="rhoai-model-registry"
MYSQL_USER="admin"
MYSQL_PASSWORD="mysql-admin"
MYSQL_DATABASE="sampledb"
MINIO_ACCESS_KEY="minio"
MINIO_SECRET_KEY="minio123"

echo "🚀 Starting AI Supply Chain Infrastructure Setup..."

# ---------------------------------------------------------------------------------
# 1. Namespace Management
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 1: Checking Namespace [$NAMESPACE]..."
if oc get project "$NAMESPACE" > /dev/null 2>&1; then
    echo "✔ Namespace $NAMESPACE already exists."
else
    echo "➤ Creating namespace $NAMESPACE..."
    oc new-project "$NAMESPACE"
fi

# ---------------------------------------------------------------------------------
# 2. Deploy MinIO (The Vault)
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 2: Deploying MinIO Object Storage (The Vault)..."
# We apply the folder containing Deployment, PVC, Service, and Route
if [ -d "quickstart/01-infrastructure/minio" ]; then
    oc apply -f quickstart/01-infrastructure/minio/ -n "$NAMESPACE"
else
    echo "❌ Error: MinIO YAML directory not found!"
    exit 1
fi

# ---------------------------------------------------------------------------------
# 3. Deploy MySQL (The Brain)
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 3: Deploying MySQL Database (The Brain)..."
# We apply the folder containing Deployment, PVC, Service, and Secret
if [ -d "quickstart/01-infrastructure/mysql" ]; then
    oc apply -f quickstart/01-infrastructure/mysql/ -n "$NAMESPACE"
else
    echo "❌ Error: MySQL YAML directory not found!"
    exit 1
fi

# ---------------------------------------------------------------------------------
# 4. Create Inter-Service Secrets
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 4: Creating Credential Secrets for Model Registry Operator..."

# Secret 1: Database Connection Secret (Used by Model Registry to talk to MySQL)
# The Registry Operator expects a secret with specific keys (user, password, database, host)
echo "➤ Creating 'model-registry-db-secret'..."
oc create secret generic model-registry-db-secret \
    --from-literal=database="$MYSQL_DATABASE" \
    --from-literal=user="$MYSQL_USER" \
    --from-literal=password="$MYSQL_PASSWORD" \
    --from-literal=host="mysql.$NAMESPACE.svc.cluster.local" \
    --from-literal=port="3306" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | oc apply -f -

# Secret 2: Storage Connection Secret (Used by the Code/Pipeline to upload models)
echo "➤ Creating 'model-registry-s3-secret'..."
oc create secret generic model-registry-s3-secret \
    --from-literal=aws_access_key_id="$MINIO_ACCESS_KEY" \
    --from-literal=aws_secret_access_key="$MINIO_SECRET_KEY" \
    --from-literal=endpoint_url="http://minio.$NAMESPACE.svc.cluster.local:9000" \
    --from-literal=region="us-east-1" \
    --from-literal=bucket="private-models" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | oc apply -f -

# ---------------------------------------------------------------------------------
# 5. Verification
# ---------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Step 5: Waiting for Infrastructure Rollout..."
echo "➤ Waiting for MySQL and MinIO to be ready (timeout: 120s)..."

oc wait --for=condition=ready pod -l app=mysql -n "$NAMESPACE" --timeout=120s
oc wait --for=condition=ready pod -l app=minio -n "$NAMESPACE" --timeout=120s

echo ""
echo "✅ SUCCESS: Infrastructure is live."
echo "   - MySQL Service: mysql.$NAMESPACE.svc.cluster.local"
echo "   - MinIO Console: https://$(oc get route minio-ui -n $NAMESPACE -o jsonpath='{.spec.host}')"
echo "   - Ready for Step 2: Model Ingestion."