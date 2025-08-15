#!/bin/bash

# ======================================
# Hàm ngủ ngẫu nhiên
# ======================================
rand_sleep() {
  sleep $((RANDOM % 3 + 2))
}

# ======================================
# 1. Gọi Discovery APIs
# ======================================
echo "[1/8] Calling Google Discovery APIs..."
APIS=("abusiveexperiencereport:v1" "books:v1" "youtube:v3" "translate:v2" "drive:v3")
for API in "${APIS[@]}"; do
  NAME="${API%%:*}"
  VERSION="${API##*:}"
  echo "Calling $NAME API..."
  curl -s "https://www.googleapis.com/discovery/v1/apis/$NAME/$VERSION/rest" >/dev/null
  rand_sleep
done

# ======================================
# 2. Gọi thử Google Translate API (Public GET)
# ======================================
echo "[2/8] Calling Google Translate public endpoint..."
curl -s "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=hello%20world" >/dev/null
rand_sleep

# ======================================
# 3. Cloud Storage: Tạo bucket, upload, download, xóa
# ======================================
echo "[3/8] Interacting with Google Cloud Storage..."
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  PROJECT_ID="warmup-project-$RANDOM"
  gcloud projects create "$PROJECT_ID"
  gcloud config set project "$PROJECT_ID"
fi

BUCKET_NAME="warmup-bucket-$RANDOM"
echo "Creating bucket: $BUCKET_NAME"
gcloud storage buckets create "$BUCKET_NAME" --location=US >/dev/null

echo "Creating test file..."
echo "Warm-up test $(date)" > test.txt

echo "Uploading file..."
gcloud storage cp test.txt gs://$BUCKET_NAME/ >/dev/null
rand_sleep

echo "Downloading file..."
gcloud storage cp gs://$BUCKET_NAME/test.txt ./test_download.txt >/dev/null
rand_sleep

echo "Deleting file & bucket..."
gcloud storage rm gs://$BUCKET_NAME/test.txt >/dev/null
gcloud storage buckets delete "$BUCKET_NAME" --quiet >/dev/null

# ======================================
# 4. Một số lệnh gcloud khác
# ======================================
echo "[4/8] Running various gcloud commands..."
gcloud compute regions list >/dev/null
rand_sleep
gcloud compute zones list >/dev/null
rand_sleep
gcloud services list --available >/dev/null
rand_sleep
gcloud iam service-accounts list >/dev/null
rand_sleep

# ======================================
# 5. Clone Git repo Google
# ======================================
echo "[5/8] Cloning Google Cloud Storage Python client..."
git clone https://github.com/googleapis/python-storage.git >/dev/null
cd python-storage
ls >/dev/null
cd ..
rand_sleep

# ======================================
# 6. Docker Compose với Nginx & Postgres
# ======================================
echo "[6/8] Setting up Docker Compose with Nginx & Postgres..."
cat <<EOF > docker-compose.yml
version: "3.8"
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
  postgres:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: example
    ports:
      - "5432:5432"
EOF

docker compose up -d
rand_sleep

git clone https://github.com/spring-guides/gs-spring-boot.git
cd gs-spring-boot/complete
./gradlew bootRun

# ======================================
# 7. Chạy web Python đơn giản
# ======================================
echo "[7/8] Running simple Python web server..."
python3 -m http.server 8080 &
SERVER_PID=$!
rand_sleep
kill $SERVER_PID

# ======================================
# 8. Hoàn tất
# ======================================
echo "[8/8] Warm-up completed!"
