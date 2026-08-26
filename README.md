rnlkav7@cloudshell:~ (mgca-notes-api-rnlkav)$ kubectl get service notes-api-deployment
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
notes-api-deployment   LoadBalancer   34.118.238.30   34.101.224.144   80:31202/TCP   18m


```bash
#setup_submission.sh

#!/bin/bash
# ==============================================================================
# SCRIPT DEPLOYMENT GCP AUTOMATION FOR DICODING SUBMISSION
# Project: Menjadi Google Cloud Architect (Notes API)
# ==============================================================================

set -e # Hentikan eksekusi jika terjadi error

# ------------------------------------------------------------------------------
# 1. DEKLARASI VARIABEL
# ------------------------------------------------------------------------------
echo "======================================================================"
echo "[STEP 1/6] Menyiapkan Variabel Konfigurasi..."
echo "======================================================================"

export PROJECT_ID=$(gcloud config get-value project)
export REGION="asia-southeast2"
export ZONE="asia-southeast2-a"
export REPO_NAME="notes-api-repo"
export CLUSTER_NAME="notes-cluster"
export DEPLOYMENT_NAME="notes-api-deployment"
export IMAGE_TAG="v1"
export REVIEWER_GROUP="group:reviewer_googlecloud@dicoding.com"

echo "Project ID    : $PROJECT_ID"
echo "Region        : $REGION"
echo "Zone          : $ZONE"
echo "Repository    : $REPO_NAME"
echo "Cluster       : $CLUSTER_NAME"
echo "Deployment    : $DEPLOYMENT_NAME"
echo "----------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# 2. AKTIFKAN API GOOGLE CLOUD
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 2/6] Mengaktifkan Service API Google Cloud..."
echo "======================================================================"
gcloud services enable \
    artifactregistry.googleapis.com \
    container.googleapis.com \
    cloudbuild.googleapis.com

# ------------------------------------------------------------------------------
# 3. BUAT ARTIFACT REGISTRY & BUILD DOCKER IMAGE
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 3/6] Membuat Artifact Registry & Build Image via Cloud Build..."
echo "======================================================================"

# Buat Repository jika belum ada
if ! gcloud artifacts repositories describe $REPO_NAME --location=$REGION &>/dev/null; then
    echo "Membuat Artifact Registry repository: $REPO_NAME..."
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker Repository for Notes API"
else
    echo "Repository $REPO_NAME sudah ada, melanjutkan..."
fi

# Build image menggunakan Cloud Build
echo "Memulai proses Cloud Build..."
IMAGE_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/notes-api:$IMAGE_TAG"
gcloud builds submit --tag $IMAGE_PATH .

# ------------------------------------------------------------------------------
# 4. BUAT CLUSTER GKE & DEPLOY APLIKASI
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 4/6] Membuat GKE Cluster & Deploy Notes API Application..."
echo "======================================================================"

# Buat Cluster GKE jika belum ada
if ! gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE &>/dev/null; then
    echo "Membuat GKE Cluster: $CLUSTER_NAME..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone=$ZONE \
        --num-nodes=2 \
        --machine-type=e2-medium
else
    echo "GKE Cluster $CLUSTER_NAME sudah ada, melanjutkan..."
fi

# Ambil Kredensial Cluster
echo "Mengambil kredensial cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Deploy Aplikasi ke GKE
if kubectl get deployment $DEPLOYMENT_NAME &>/dev/null; then
    echo "Updating existing deployment image..."
    kubectl set image deployment/$DEPLOYMENT_NAME notes-api=$IMAGE_PATH
    kubectl rollout restart deployment/$DEPLOYMENT_NAME
else
    echo "Membuat deployment baru..."
    kubectl create deployment $DEPLOYMENT_NAME --image=$IMAGE_PATH
fi

# ------------------------------------------------------------------------------
# 5. EXPOSE SERVICE LOAD BALANCER (PORT 80:5000)
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 5/6] Konfigurasi Service LoadBalancer (Port 80)..."
echo "======================================================================"

if kubectl get service $DEPLOYMENT_NAME &>/dev/null; then
    echo "Memperbarui service yang ada..."
    kubectl delete service $DEPLOYMENT_NAME
fi

echo "Exposing deployment pada Port Mapping 80:5000..."
kubectl expose deployment $DEPLOYMENT_NAME \
    --type=LoadBalancer \
    --port=80 \
    --target-port=5000

# ------------------------------------------------------------------------------
# 6. ATUR HAK AKSES IAM (LEAST PRIVILEGE ACCORDING TO REQUIREMENTS)
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 6/6] Menerapkan Hak Akses IAM (Principle of Least Privilege)..."
echo "======================================================================"

# Akses Reader spesifik untuk Artifact Registry Repository
echo "Memberikan akses Reader pada Artifact Registry..."
gcloud artifacts repositories add-iam-policy-binding $REPO_NAME \
    --location=$REGION \
    --member="$REVIEWER_GROUP" \
    --role="roles/artifactregistry.reader"

# Akses Viewer spesifik untuk GKE
echo "Memberikan akses GKE Viewer pada level Project..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="$REVIEWER_GROUP" \
    --role="roles/container.viewer"

# ------------------------------------------------------------------------------
# FINISH & VERIFIKASI EXTERNAL IP
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo " PROSES DEPLOYMENT SELESAI!"
echo "======================================================================"
echo "Menampilkan status LoadBalancer Service..."
echo ""

kubectl get service $DEPLOYMENT_NAME
```