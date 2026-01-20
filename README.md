# Red Hat OpenShift AI 3.0 Model Registry - Deployment Guide

**From Shadow IT to Trusted Assets**

> **The Problem:** Data Scientists are downloading models to random laptops and S3 buckets.  
> **The Solution:** A Private Model Registry that governs your AI assets ("The Vault") and connects them to the OpenShift AI Dashboard ("The Showroom").

This repository provides deployment scripts and configuration to deploy, populate, and integrate the Red Hat OpenShift AI (RHOAI) Model Registry.

📚 **Full Course Documentation:** The complete course with detailed explanations, architecture diagrams, and troubleshooting guides is available on [GitHub Pages](https://redhatquickcourses.github.io/rhoai3-registry/).

---

## Prerequisites

* **Cluster:** OpenShift AI 3.0 installed and accessible
* **Access:** `cluster-admin` privileges (required to create Model Registry CR and manage namespaces)
* **CLI Tools:** `oc` CLI installed and authenticated (`oc login`)
* **Repository:** Clone this repository:
  ```bash
  git clone https://github.com/RedHatQuickCourses/rhoai3-registry.git
  cd rhoai3-registry/
  ```

---

## Quick Start: Deploy Model Registry

Follow these steps to get your Model Registry up and running with models visible in the OpenShift AI Model Catalog.

### Step 1: Deploy Infrastructure ("The Plumbing")

Deploy MySQL database and MinIO object storage in the lab namespace.

```bash
chmod +x deploy/setup.sh
./deploy/setup.sh
```

**What this does:**
- Creates namespace `rhoai-model-registry-lab`
- Deploys MySQL 8.0 (metadata storage)
- Deploys MinIO (object storage for model artifacts)
- Creates S3 data connection secret for RHOAI

**Verify infrastructure is ready:**
```bash
oc get pods -n rhoai-model-registry-lab
```

Wait until all pods show `Running` status:
```
NAME                              READY   STATUS    RESTARTS   AGE
mysql-5d8f7-xyz                   1/1     Running   0          45s
minio-7b9c2-abc                   1/1     Running   0          45s
s3-ui-6d87f-rst                   1/1     Running   0          20s
```

### Step 2: Create Database Secret for Model Registry

The Model Registry needs credentials to connect to MySQL. Create the secret in the `rhoai-model-registries` namespace:

```bash
oc create secret generic registry-db-secret \
  -n rhoai-model-registries \
  --from-literal=database-host='mysql.rhoai-model-registry-lab.svc.cluster.local' \
  --from-literal=database-port='3306' \
  --from-literal=database-name='sampledb' \
  --from-literal=database-user='admin' \
  --from-literal=database-password='mysql-admin'
```

### Step 3: Deploy the Model Registry

Create the Model Registry Custom Resource that connects to your MySQL database:

```bash
oc apply -f deploy/catalog/model_registry_setup.yaml
```

**Verify the Model Registry is running:**
```bash
oc get modelregistries.modelregistry.opendatahub.io -n rhoai-model-registries
oc get pods -n rhoai-model-registries -l app=model-registry
```

The Model Registry pod should be in `Running` status.

### Step 4: Register a Model ("The Content")

Run the automated pipeline to download a model from Hugging Face, upload it to MinIO, and register it in the Model Registry:

```bash
chmod +x deploy/run_pipeline.sh
./deploy/run_pipeline.sh
```

**What this does:**
- Downloads `Qwen/Qwen3-0.6B` model from Hugging Face
- Uploads model artifacts to MinIO (`s3://private-models/`)
- Registers model metadata in the Model Registry

**Monitor the job:**
The script will stream logs. Wait for the success message:
```
✅ SUCCESS: Supply Chain Complete!
    Model ID: <model-id>
    Version: 1.0.0
```

### Step 5: Connect the Model Catalog ("The Showroom")

Apply the catalog configuration to make your registered models visible in the OpenShift AI Dashboard:

```bash
oc apply -f deploy/catalog/catalog-source.yaml
```

This creates a ConfigMap (`model-catalog-sources`) that the Model Catalog service reads to display your private registry models.

**Force catalog refresh (if models don't appear immediately):**
```bash
oc delete pod -l component=model-catalog -n rhoai-model-registries
```

Wait for the new pod to start:
```bash
oc get pods -l component=model-catalog -n rhoai-model-registries -w
```

### Step 6: Verify in OpenShift AI Dashboard

1. Open the **Red Hat OpenShift AI Dashboard** in your browser
2. Navigate to **Model Catalog** in the left sidebar
3. Look for your custom catalog source (e.g., "Training Lab Models" or "Model-Registry-Lab")
4. You should see the registered model (e.g., "Qwen3-0.6B")
5. Click the model card to verify it shows your private S3 URI (not Hugging Face)

**Note:** If you don't see your models:
- Check the catalog source filter in the UI - ensure your custom source is selected
- Verify the ConfigMap was created: `oc get configmap model-catalog-sources -n rhoai-model-registries`
- Check catalog pod logs: `oc logs -l component=model-catalog -n rhoai-model-registries`

---

## Repository Structure

```
/
├── deploy/                      # Deployment scripts and configurations
│   ├── infrastructure/         # MySQL & MinIO YAMLs
│   │   ├── minio/               # MinIO deployment, PVC, Service, Route
│   │   └── mysql/               # MySQL deployment, PVC, Service, Secret
│   ├── registration/            # Model ingestion scripts
│   │   ├── ingest_model.py      # Downloads model from Hugging Face
│   │   ├── register_model.py    # Registers model in Model Registry
│   │   └── requirements.txt    # Python dependencies
│   ├── catalog/                 # Model Catalog integration
│   │   ├── catalog-source.yaml  # ConfigMap for catalog display
│   │   └── model_registry_setup.yaml  # Model Registry CR
│   ├── setup.sh                 # Infrastructure deployment script
│   └── run_pipeline.sh          # Model ingestion pipeline
│
├── modules/                     # Course documentation (AsciiDoc source)
│   └── chapter1/                # Lab instructions and guides
│
└── README.md                    # This file
```

---

## Troubleshooting

### Model Registry Pod Not Starting

**Check database connection:**
```bash
oc logs -n rhoai-model-registries deployment/model-registry-service
```

Look for errors like `Access denied for user` or `Connection refused`. Verify the database secret:
```bash
oc get secret registry-db-secret -n rhoai-model-registries
```

### Models Not Appearing in Catalog

1. **Verify the ConfigMap exists:**
   ```bash
   oc get configmap model-catalog-sources -n rhoai-model-registries -o yaml
   ```

2. **Check catalog pod logs:**
   ```bash
   oc logs -l component=model-catalog -n rhoai-model-registries
   ```

3. **Restart the catalog pod:**
   ```bash
   oc delete pod -l component=model-catalog -n rhoai-model-registries
   ```

4. **Verify Model Registry has registered models:**
   ```bash
   # Check if models are registered (requires Model Registry API access)
   oc get pods -n rhoai-model-registries -l app=model-registry
   ```

### Pipeline Job Fails

**Check job logs:**
```bash
oc logs job/model-ingest-job -n rhoai-model-registry-lab
```

**Common issues:**
- **Network errors:** Ensure pod can reach Hugging Face and MinIO
- **S3 upload failures:** Verify MinIO credentials in `aws-connection-minio` secret
- **Registry connection:** Verify Model Registry service is running and accessible

### Database Connection Failed

Verify the database secret matches your MySQL deployment:
```bash
oc get secret registry-db-secret -n rhoai-model-registries -o jsonpath='{.data.database-host}' | base64 -d
```

Should match: `mysql.rhoai-model-registry-lab.svc.cluster.local`

---

## Next Steps

Once your Model Registry is deployed and models are visible in the catalog:

- **Deploy models** directly from the OpenShift AI Dashboard Model Catalog
- **Register additional models** by running `./deploy/run_pipeline.sh` with different model IDs
- **Customize the catalog** by editing the ConfigMap: `oc edit configmap model-catalog-sources -n rhoai-model-registries`

For detailed explanations, architecture diagrams, and advanced troubleshooting, see the [full course documentation](https://redhatquickcourses.github.io/rhoai3-registry/).

---

## Additional Resources

- **Full Course:** [GitHub Pages Documentation](https://redhatquickcourses.github.io/rhoai3-registry/)
- **OpenShift AI Documentation:** [Red Hat Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/)
- **Model Registry API:** See `deploy/registration/` for Python examples
