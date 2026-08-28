#!/bin/bash
# ==============================================================================
# SCRIPT CLEANUP GCP AUTOMATION (OPTIMIZED & FAST)
# Project: Menjadi Google Cloud Architect (Notes API)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. DEKLARASI VARIABEL
# ------------------------------------------------------------------------------
echo "======================================================================"
echo "[STEP 1/5] Menyiapkan Variabel Konfigurasi..."
echo "======================================================================"

export PROJECT_ID=$(gcloud config get-value project)
export REGION="asia-southeast2"
export ZONE="asia-southeast2-a"
export REPO_NAME="notes-api-repo"
export CLUSTER_NAME="notes-cluster"
export DEPLOYMENT_NAME="notes-api-deployment"
export REVIEWER_GROUP="group:reviewer_googlecloud@dicoding.com"

echo "Project ID    : $PROJECT_ID"
echo "Region        : $REGION"
echo "Zone          : $ZONE"
echo "Repository    : $REPO_NAME"
echo "Cluster       : $CLUSTER_NAME"
echo "----------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# 2. HAPUS KUBERNETES SERVICE & DEPLOYMENT (DENGAN CEK CLUSTER)
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 2/5] Menghapus Kubernetes Service & Deployment..."
echo "======================================================================"

# Cek apakah cluster GKE masih ada sebelum mencoba menghubungkan kubectl
if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE &>/dev/null; then
    echo "Cluster ditemukan. Menghubungkan ke $CLUSTER_NAME..."
    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --quiet || true

    echo "Menghapus Service $DEPLOYMENT_NAME..."
    kubectl delete service $DEPLOYMENT_NAME --ignore-not-found=true --request-timeout='10s' || true

    echo "Menghapus Deployment $DEPLOYMENT_NAME..."
    kubectl delete deployment $DEPLOYMENT_NAME --ignore-not-found=true --request-timeout='10s' || true
else
    echo "Cluster $CLUSTER_NAME tidak ditemukan/sudah terhapus. Melompati langkah kubectl."
fi

# ------------------------------------------------------------------------------
# 3. HAPUS CLUSTER GKE
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 3/5] Menghapus GKE Cluster..."
echo "======================================================================"

if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE &>/dev/null; then
    echo "Menghapus GKE Cluster: $CLUSTER_NAME..."
    gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE --quiet || true
else
    echo "GKE Cluster $CLUSTER_NAME sudah tidak ada, melompati..."
fi

# ------------------------------------------------------------------------------
# 4. HAPUS ARTIFACT REGISTRY REPOSITORY
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 4/5] Menghapus Artifact Registry Repository..."
echo "======================================================================"

if gcloud artifacts repositories describe $REPO_NAME --location=$REGION &>/dev/null; then
    echo "Menghapus Artifact Registry Repository: $REPO_NAME..."
    gcloud artifacts repositories delete $REPO_NAME --location=$REGION --quiet || true
else
    echo "Repository $REPO_NAME sudah tidak ada, melompati..."
fi

# ------------------------------------------------------------------------------
# 5. MENCABUT HAK AKSES IAM REVIEWER
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "[STEP 5/5] Mencabut Hak Akses IAM Reviewer..."
echo "======================================================================"

echo "Mencabut akses Artifact Registry Reader dari $REVIEWER_GROUP..."
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="$REVIEWER_GROUP" \
    --role="roles/artifactregistry.reader" 2>/dev/null || true

echo "Mencabut akses Kubernetes Engine Viewer dari $REVIEWER_GROUP..."
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="$REVIEWER_GROUP" \
    --role="roles/container.viewer" 2>/dev/null || true

echo ""
echo "======================================================================"
echo " PROSES CLEANUP SELESAI SANGAT CEPAT!"
echo "======================================================================"