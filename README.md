📚 Option 1: View the Full Course (Antora)
This repository is structured as an Antora documentation site. To view the full learning experience, including architecture deep-dives and SRE playbooks:

Using Docker
Bash

docker run -u $(id -u) -v $PWD:/antora:Z --rm -t antora/antora playbook.yaml
⚡ Option 2: The Fast Track (Lab Deployment)
Follow these steps to deploy the infrastructure and register your first governed model.

Prerequisites

Platform: Red Hat OpenShift AI v3.0.


Access: cluster-admin privileges.



CLI: oc logged into your cluster.


Repository: Cloned rhoai3-registry repository.

Step 1: Deploy Infrastructure ("The Brain & The Vault")
Deploy the MySQL 8.0 database and MinIO object storage into the rhoai-model-registry-lab namespace.

Bash

chmod u+x ./deploy/setup.sh
./deploy/setup.sh

Wait for pods in the namespace to reach Running status before proceeding.

Step 2: Link the Registry to the Database
Apply the ModelRegistry custom resource to connect the service to the MySQL backend.

Bash

oc apply -f deploy/registry/model-registry.yaml
Step 3: Automated Ingestion & Registration
Run the pipeline to download the Qwen3-0.6B model, upload it to your private vault (MinIO), and register versioned metadata in the registry.

Bash

chmod u+x ./deploy/run_pipeline.sh
./deploy/run_pipeline.sh
Step 4: Connect the Catalog ("The Showroom")
The Model Catalog uses a Kubernetes ConfigMap for configuration. Edit this object directly to add your private registry sources.


Bash

oc project rhoai-model-registries
oc edit configmap model-catalog-sources

Action: Insert the sources.yaml and registry-models.yaml definitions into the data: section of the ConfigMap.


Step 5: Visual Verification
Open the OpenShift AI Dashboard.

Navigate to Model Catalog in the sidebar.

Look for the "Model-Registry-Lab" source and the Qwen3-0.6B card.


🛠 Troubleshooting & Day 2 Operations

Pod Failures: Status CrashLoopBackOff usually indicates a database connection failure; verify the registry-db-secret matches your MySQL credentials.



Storage Access: Ensure the Registry pod can reach the MinIO service via the internal cluster network.


Catalog Visibility: If models do not appear, check the Dashboard logs for YAML parsing errors in the ConfigMap.


Emergency Reset: Delete the rhoai-model-registry-lab project and re-run the setup script to start from scratch.

📂 Repository Structure
modules/ROOT/pages/: Source content (Adoc) for the Antora course.

deploy/infrastructure/: YAML configurations for MySQL and MinIO.

deploy/registration/: Python automation scripts for model ingestion.

deploy/catalog/: YAML templates for Dashboard ConfigMap integration.
