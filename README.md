Here is the **`README.md`** for the repository root.

This file serves two purposes:

1. It documents how to build the full course (Antora).
2. It acts as a **"Cheat Sheet"** for advanced users who want to run the lab immediately without reading the full course text.

---

**File Name:** `README.md`

```markdown
# The AI Supply Chain: Red Hat OpenShift AI 3.0 Model Registry
**From Shadow IT to Trusted Assets**

> **The Problem:** Data Scientists are downloading models to random laptops and S3 buckets.  
> **The Solution:** A Private Model Registry that governs your AI assets ("The Vault") and connects them to the OpenShift AI Dashboard ("The Showroom").

This repository contains a complete **"Course-in-a-Box"** that teaches you how to deploy, populate, and integrate the Red Hat OpenShift AI (RHOAI) Model Registry.

---

## 📚 Option 1: View the Full Course (Antora)

This repository is structured as an Antora documentation site. To view the full learning experience with diagrams, architecture deep-dives, and troubleshooting guides:

### Using Docker (Recommended)
```bash
docker run -u $(id -u) -v $PWD:/antora:Z --rm -t antora/antora playbook.yaml
# Open the generated site:
# open build/site/index.html

```

### Using Local NPM

```bash
npm install
npx antora playbook.yaml
# Open build/site/index.html

```

---

## ⚡ Option 2: The Fast Track (Deployment Guide)

If you are an experienced Platform Engineer and just want to deploy the solution **now**, follow these steps.

### Prerequisites

* **Cluster:** OpenShift AI 3.0 installed.
* **Access:** `cluster-admin` privileges (required to install Registry dependencies).
* **CLI:** `oc` and `python3` installed locally.

### Step 1: Deploy Infrastructure ("The Plumbing")

Create the namespace, MySQL database, and MinIO object storage.

```bash
./quickstart/01-infrastructure/setup.sh

```

*Wait for pods in `rhoai-model-registry` to be `Running`.*

### Step 2: Ingest & Register a Model ("The Content")

Run the automated pipeline to:

1. Download `granite-7b-lab` from Hugging Face.
2. Upload it to your private MinIO bucket.
3. Register the metadata in the Model Registry.

```bash
# Install dependencies (if needed)
pip install -r quickstart/02-registration-code/requirements.txt

# Run the pipeline (Internal DNS Mode)
./quickstart/02-registration-code/run_pipeline.sh

```

### Step 3: Connect the Catalog ("The UI")

Apply the configuration that tells the RHOAI Dashboard to display your private registry models.

```bash
oc apply -f quickstart/03-catalog/catalog-source.yaml

```

### Step 4: Verify

1. Open the **OpenShift AI Dashboard**.
2. Go to **Model Catalog**.
3. Look for the **"Private Enterprise Registry"** tab.
4. Deploy the **Granite-7B-Enterprise** model.

---

## 📂 Repository Structure

```text
/
├── content/                  # Antora Course Source (Adoc files)
│   └── modules/ROOT/pages/   # The actual learning content
│
├── quickstart/               # The Lab Code
│   ├── 01-infrastructure/    # MySQL & MinIO YAMLs
│   ├── 02-registration-code/ # Python Ingestion Scripts
│   └── 03-catalog/           # Dashboard Integration YAML
│
└── playbook.yaml             # Antora Build Configuration

```

## 🛠 Troubleshooting

* **Database Connection Failed?** Check `oc get secret model-registry-db-secret -n rhoai-model-registry`.
* **Script Can't Connect?** Ensure you are running the python scripts from a terminal *inside* the cluster, OR use `oc port-forward` if running locally (see `troubleshooting.adoc`).

```

***

### Next Steps for You
This concludes the creation of the repository assets. You now have the full package:
1.  **Course Content** (Adoc pages).
2.  **Lab Infrastructure** (YAMLs & Setup Script).
3.  **Automation Logic** (Python & Bash).
4.  **Documentation** (README).

Would you like me to finally generate the **`playbook.yaml`** so you can physically build this site, or is there anything else you need to refine?

```