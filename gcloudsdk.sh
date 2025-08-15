#!/bin/bash
# =========================================
# Google Cloud "Warm-up" Complete Script
# =========================================

echo "=== GCP Warm-up Script Started ==="
echo "=== GCP Warm-up SDK! ==="
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
# ---------------------------
# 0. Kiểm tra môi trường
# ---------------------------
command -v gcloud >/dev/null 2>&1 || { echo "gcloud CLI not found!"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Python3 not found!"; exit 1; }

# ---------------------------
# 1. Random sleep function
# ---------------------------
rand_sleep() {
  sleep $((RANDOM % 5 + 2))  # 2–6s random
}

# ---------------------------
# 2. Gọi Discovery APIs
# ---------------------------
echo "[1/8] Calling Discovery APIs..."
APIS=("abusiveexperiencereport:v1" "books:v1" "youtube:v3" "translate:v2" "drive:v3")
for API in "${APIS[@]}"; do
  NAME="${API%%:*}"
  VERSION="${API##*:}"
  echo "Calling $NAME API..."
  curl -s "https://www.googleapis.com/discovery/v1/apis/$NAME/$VERSION/rest" >/dev/null
  rand_sleep
done

# ---------------------------
# 3. Gọi API đọc dữ liệu
# ---------------------------
echo "[2/8] Calling public APIs..."
# Books
curl -s "https://www.googleapis.com/books/v1/volumes?q=cloud+computing" >/dev/null
rand_sleep
# Translate
curl -s "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=hello+world" >/dev/null
rand_sleep
# YouTube
curl -s "https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular&maxResults=1&regionCode=US" >/dev/null
rand_sleep

# ---------------------------
# 4. Gcloud Storage upload/download
# ---------------------------
echo "[3/8] Create bucket + upload/download file..."
BUCKET_NAME="warmup-bucket-$RANDOM"
gcloud storage buckets create $BUCKET_NAME --location=US

# File test
echo "Warm-up file for GCP - $(date)" > warmup_test.txt
gcloud storage cp warmup_test.txt gs://$BUCKET_NAME/warmup_test.txt
rand_sleep
gcloud storage cp gs://$BUCKET_NAME/warmup_test.txt downloaded_warmup_test.txt
rand_sleep

# ---------------------------
# 5. Query Compute Engine lightly
# ---------------------------
echo "[4/8] Query Compute Engine..."
gcloud compute zones list --limit=2
rand_sleep
ZONES=$(gcloud compute zones list --limit=1 --format="value(name)")
gcloud compute machine-types list --zones=$ZONES --limit=3
rand_sleep

# ---------------------------
# 6. Clone Python Storage SDK & test
# ---------------------------
echo "[5/8] Clone python-storage repo..."
git clone https://github.com/googleapis/python-storage.git
cd python-storage
ls -lah | head -n 10
rand_sleep

echo "[6/8] Installing SDK & running Python example..."
pip3 install -q google-cloud-storage || true

cat <<EOF > gcs_example.py
from google.cloud import storage
import os

bucket_name = "$BUCKET_NAME"
file_name = "sdk_test.txt"

with open(file_name, "w") as f:
    f.write("GCS SDK test file - warm-up")

client = storage.Client()
bucket = client.bucket(bucket_name)
blob = bucket.blob(file_name)
blob.upload_from_filename(file_name)
print("[PYTHON SDK] Uploaded:", file_name)

for blob in bucket.list_blobs():
    print("[PYTHON SDK] Found object:", blob.name)
EOF

python3 gcs_example.py || echo "[!] Python SDK example failed"
cd ..
rand_sleep

# ---------------------------
# 7. Cleanup
# ---------------------------
echo "[7/8] Cleanup bucket & files..."
gcloud storage rm gs://$BUCKET_NAME/warmup_test.txt || true
gcloud storage rm gs://$BUCKET_NAME/sdk_test.txt || true
gcloud storage buckets delete $BUCKET_NAME --quiet || true
rm -rf warmup_test.txt downloaded_warmup_test.txt python-storage gcs_example.py

# ---------------------------
# 8. Done
# ---------------------------
echo "=== GCP Warm-up Completed Successfully! ==="


echo "=== GCP Warm-up Spring! ==="
git clone https://github.com/spring-guides/gs-spring-boot.git
cd gs-spring-boot/complete
./gradlew bootRun
echo "=== GCP Warm-up Completed Successfully! ==="
