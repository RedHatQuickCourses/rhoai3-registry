import os
from model_registry import ModelRegistry

# --- CONFIGURATION (Defaults for In-Cluster Execution) ---
# Internal K8s DNS for Registry Service
REGISTRY_HOST = os.getenv("REGISTRY_HOST", "model-registry-service.rhoai-model-registry.svc.cluster.local")
REGISTRY_PORT = int(os.getenv("REGISTRY_PORT", 8080))
MODEL_NAME = "Granite-7B-Enterprise"
VERSION = "1.0.0"

def register():
    # 1. Read the S3 URI from the previous step
    if not os.path.exists("model_uri.txt"):
        print("❌ ERROR: model_uri.txt not found. Did Step 1 run?")
        exit(1)
        
    with open("model_uri.txt", "r") as f:
        s3_uri = f.read().strip()

    print(f"=== STEP 3: GOVERNANCE & REGISTRATION ===")
    print(f"--> Connecting to Registry at {REGISTRY_HOST}:{REGISTRY_PORT}...")
    
    # Secure connection false because we are using internal HTTP service
    registry = ModelRegistry(server_address=REGISTRY_HOST, port=REGISTRY_PORT, author="QuickStart Admin", is_secure=False)

    # 2. Register the Model
    print(f"--> Creating Model Entity: '{MODEL_NAME}'...")
    
    # Check if model exists, if not create
    # Note: The logic here handles the specific RHOAI Model Registry flow
    model = registry.register_model(
        MODEL_NAME, 
        s3_uri, 
        model_format_name="safetensors", 
        model_format_version="1.0",
        version=VERSION,
        description="Approved Granite 7B model for internal RAG applications.",
        metadata={
            "approved_for_production": "true",
            "license": "Apache-2.0",
            "source_repo": "ibm-granite/granite-7b-lab"
        }
    )

    print(f"\n✅ SUCCESS: Model Registered!")
    print(f"    ID: {model.id}")
    print(f"    Version: {VERSION}")
    print(f"    Location: {s3_uri}")
    print(f"    Registry: http://{REGISTRY_HOST}:{REGISTRY_PORT}")

if __name__ == "__main__":
    register()