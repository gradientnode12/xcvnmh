#!/bin/bash
set -e

# ========= CONFIG =========
PROJECT_ID="spring-firebase4345-$(date +%s)"
PROJECT_NAME="Spring Boot Firebase App"
REGION="us-central1"
SERVICE_NAME="firebase-spring-app"

# ========= STEP 1: CREATE FIREBASE PROJECT =========
echo "👉 Tạo GCP project: $PROJECT_ID"
gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"

echo "👉 Kích hoạt Firebase cho project"
gcloud alpha firebase projects add-gcp-project $PROJECT_ID

# ========= STEP 2: ENABLE APIS =========
echo "👉 Bật API cần thiết"
gcloud services enable \
  firebase.googleapis.com \
  firestore.googleapis.com \
  appengine.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com \
  --project=$PROJECT_ID

# ========= STEP 3: CREATE SPRING BOOT APP =========
echo "👉 Tạo Spring Boot app mẫu"
mkdir $PROJECT_ID && cd $PROJECT_ID
curl https://start.spring.io/starter.zip \
    -d dependencies=web \
    -d name=FirebaseSpringApp \
    -d artifactId=$SERVICE_NAME \
    -o app.zip

unzip app.zip -d app
cd app

# ========= STEP 4: ADD FIREBASE ADMIN SDK =========
echo "👉 Thêm Firebase Admin SDK vào pom.xml"
sed -i '/<\/dependencies>/ i\
        <dependency>\n\
            <groupId>com.google.firebase</groupId>\n\
            <artifactId>firebase-admin</artifactId>\n\
            <version>9.2.0</version>\n\
        </dependency>' pom.xml

# ========= STEP 5: CREATE SERVICE ACCOUNT =========
echo "👉 Tạo Service Account"
gcloud iam service-accounts create spring-admin --project=$PROJECT_ID

gcloud iam service-accounts keys create src/main/resources/firebase-key.json \
  --iam-account=spring-admin@$PROJECT_ID.iam.gserviceaccount.com \
  --project=$PROJECT_ID

# ========= STEP 6: CREATE SIMPLE CONTROLLER =========
echo "👉 Tạo REST Controller mẫu"
mkdir -p src/main/java/com/example/demo
cat > src/main/java/com/example/demo/DemoController.java <<'EOF'
package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DemoController {
    @GetMapping("/")
    public String hello() {
        return "✅ Spring Boot + Firebase CLI App is running!";
    }
}
EOF

# ========= STEP 7: DEPLOY TO CLOUD RUN =========
echo "👉 Build và deploy lên Cloud Run"
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME --project=$PROJECT_ID

gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --project=$PROJECT_ID

URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --project=$PROJECT_ID --format='value(status.url)')

echo "✅ DONE! App Spring Boot + Firebase đã chạy tại:"
echo "👉 $URL"
