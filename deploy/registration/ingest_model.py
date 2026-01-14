import os
import boto3
from huggingface_hub import snapshot_download
from botocore.client import Config

# --- CONFIGURATION (Defaults for In-Cluster Execution) ---
MODEL_ID = os.getenv("MODEL_ID", "Qwen/Qwen3-0.6B")
# Internal K8s DNS for MinIO Service
S3_ENDPOINT = os.getenv("S3_ENDPOINT", "http://minio-service.rhoai-model-registry-lab.svc.cluster.local:9000")
S3_BUCKET = os.getenv("S3_BUCKET", "private-models")
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY", "minio")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY", "minio123")

def upload_to_s3(local_path, s3_prefix):
    print(f"--> Connecting to Private Vault at {S3_ENDPOINT}...")
    try:
        s3 = boto3.client('s3',
                          endpoint_url=S3_ENDPOINT,
                          aws_access_key_id=AWS_ACCESS_KEY,
                          aws_secret_access_key=AWS_SECRET_KEY,
                          config=Config(signature_version='s3v4'))
        # Simple check to see if we can talk to the endpoint
        s3.list_buckets()
    except Exception as e:
        print(f"\n❌ ERROR: Could not connect to MinIO at {S3_ENDPOINT}")
        print(f"   Are you running this inside the cluster? If not, you need port-forwarding.")
        raise e

    # Ensure bucket exists
    try:
        s3.create_bucket(Bucket=S3_BUCKET)
    except:
        pass # Bucket likely exists

    print(f"--> Uploading artifacts to s3://{S3_BUCKET}/{s3_prefix}...")
    
    uploaded_uri = f"s3://{S3_BUCKET}/{s3_prefix}"
    
    for root, dirs, files in os.walk(local_path):
        for file in files:
            local_file = os.path.join(root, file)
            relative_path = os.path.relpath(local_file, local_path)
            s3_key = os.path.join(s3_prefix, relative_path)
            
            # Optional: Print every file or just progress
            # print(f"    - Uploading {relative_path}...")
            s3.upload_file(local_file, S3_BUCKET, s3_key)
            
    return uploaded_uri

def main():
    print(f"=== STEP 1: ACQUIRING ASSETS ===")
    print(f"--> Downloading '{MODEL_ID}' from Hugging Face...")
    # Only download essential files to save space in the terminal pod
    local_dir = snapshot_download(repo_id=MODEL_ID, 
                                  allow_patterns=["*.json", "*.safetensors", "*.model"])
    
    print(f"=== STEP 2: SECURING ASSETS ===")
    s3_uri = upload_to_s3(local_dir, "Qwen3-0.6B")
    
    print(f"\n✅ SUCCESS: Model Secured at {s3_uri}")
    # Write URI to file for the next script to read
    with open("model_uri.txt", "w") as f:
        f.write(s3_uri)

if __name__ == "__main__":
    main()



cat <<EOF | oc apply -f -
apiVersion: modelregistry.opendatahub.io/v1beta1
kind: ModelRegistry
metadata:
  name: model-registry-lab
  namespace: rhoai-model-registries
spec:
  grpc:
    port: 9090
  rest:
    port: 8080
  mysql:
    # NETWORK BRIDGE: We use the full DNS name to reach the lab namespace
    host: "mysql.rhoai-model-registry-lab.svc.cluster.local"
    port: 3306
    database: "sampledb"
    username: "admin"
    passwordSecret:
      name: "registry-db-secret"
      key: "database-password"
    sslMode: "disable"

  # (Optional) If using Postgres instead of MySQL, use the 'postgres' block instead.
EOF