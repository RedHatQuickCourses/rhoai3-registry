#!/bin/bash

# =================================================================================
# SCRIPT: run_pipeline.sh (Cluster Terminal Version)
# DESCRIPTION: Orchestrates the Ingestion and Registration using Internal DNS.
# =================================================================================

echo "🚀 Starting AI Supply Chain Pipeline (Internal Mode)..."

# 1. Install Dependencies
# We assume the terminal has python3 and pip. 
# We install locally to the user's home if root access is restricted.
if ! python3 -c "import model_registry" &> /dev/null; then
    echo "----------------------------------------------------------------"
    echo "Step 0: Installing Python dependencies..."
    pip install -q --user -r deploy/registration/requirements.txt
fi

# 2. Run Ingestion (HF -> Internal MinIO)
echo "----------------------------------------------------------------"
echo "Step 1: Running Data Ingestion..."
# We explicitly set the internal endpoints, though the python script defaults to them.
export S3_ENDPOINT="http://minio-service.rhoai-model-registry.svc.cluster.local:9000"
python3 deploy/registration/ingest_model.py

# Check if previous command failed
if [ $? -ne 0 ]; then
    echo "❌ Ingestion Failed. Exiting."
    exit 1
fi

# 3. Run Registration (Internal MinIO -> Internal Registry)
echo "----------------------------------------------------------------"
echo "Step 2: Running Metadata Registration..."
export REGISTRY_HOST="model-registry-service.rhoai-model-registry.svc.cluster.local"
export REGISTRY_PORT="8080"
python3 deploy/registration/register_model.py

echo "----------------------------------------------------------------"
echo "🏁 Pipeline Complete."
echo "   Next: Apply the Catalog Source YAML to see the results in the UI."