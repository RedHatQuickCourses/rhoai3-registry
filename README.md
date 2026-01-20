📚 Option 1: View the Full Course (Antora)
This repository is structured as an Antora documentation site. To view the full learning experience, including architecture deep-dives and SRE playbooks:

Using Docker
Bash

docker run -u $(id -u) -v $PWD:/antora:Z --rm -t antora/antora playbook.yaml
# Open build/site/index.html
Using Local NPM
Bash

npm install
npx antora playbook.yaml
# Open build/site/index.html
⚡ Option 2: The Fast Track (Lab Deployment)
Follow these steps to deploy the infrastructure and register your first governed model.

Prerequisites

Platform: Red Hat OpenShift AI v3.0.
Access: cluster-admin privileges.
CLI: oc logged into your cluster.

Step 1: Deploy Infrastructure ("The Brain & The Vault")
Deploy the MySQL 8.0 database and MinIO object storage into the lab namespace.

Bash

chmod u+x ./deploy/setup.sh
./deploy/setup.sh

Wait for pods in rhoai-model-registry-lab to reach Running status.

Step 2: Link the Registry to the Database
Apply the ModelRegistry custom resource to connect the service to the MySQL backend.

Bash

oc apply -f deploy/registry/model-registry.yaml
Step 3: Automated Ingestion & Registration
Run the pipeline to download the Qwen3-0.6B model, upload it to your private vault, and register versioned metadata.


Bash

chmod u+x ./deploy/run_pipeline.sh
./deploy/run_pipeline.sh
Step 4: Connect the Catalog ("The Showroom")
The Model Catalog uses a Kubernetes ConfigMap for configuration. Edit this object to add your private registry sources.



Bash

oc project rhoai-model-registries
oc edit configmap model-catalog-sources

Insert the sources.yaml and registry-models.yaml definitions as specified in the lab.

Step 5: Visual Verification
Open the OpenShift AI Dashboard.

Navigate to Model Catalog.

Look for the "Model-Registry-Lab" source and the Qwen3-0.6B card.

🛠 Troubleshooting & Day 2 Operations

Pod Failures: Check if the Registry pod is in CrashLoopBackOff, which usually indicates a database connection error.


Access Denied: Verify that the registry-db-secret matches your MySQL credentials.


Catalog Visibility: If models don't appear, check the Dashboard logs for YAML parsing errors in the ConfigMap.


Emergency Reset: To restart the lab, delete the rhoai-model-registry-lab project and re-run the setup script.

📂 Repository Structure
modules/ROOT/pages/: Source content for the Antora course.


deploy/infrastructure/: YAMLs for MySQL and MinIO.


deploy/registration/: Python scripts for automated model ingestion.


deploy/catalog/: Configuration for Dashboard integration.
