#!/bin/bash
set -e

# ========= CONFIG =========
PROJECT_ID="spring-firebase-$(date +%s)"
PROJECT_NAME="Spring Boot Firebase App"
REGION="us-central1"
SERVICE_NAME="spring-firebase-app"

# ========= STEP 1: CREATE FIREBASE PROJECT =========
echo "👉 Tạo GCP project: $PROJECT_ID"
gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"

echo "👉 Kích hoạt Firebase cho project"
gcloud alpha firebase projects add-gcp-project $PROJECT_ID

# ========= STEP 2: ENABLE APIS =========
echo "👉 Bật API cần thiết"
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  --project=$PROJECT_ID

# ========= STEP 3: DOWNLOAD SPRING INITIALIZR APP =========
echo "👉 Sinh Spring Boot app từ start.spring.io"
mkdir $PROJECT_ID && cd $PROJECT_ID
curl https://start.spring.io/starter.zip \
    -d dependencies=web \
    -d name=SpringFirebaseApp \
    -d artifactId=$SERVICE_NAME \
    -d packageName=com.example.firebase \
    -o app.zip

unzip app.zip -d app
cd app

# ========= STEP 4: CREATE SIMPLE CONTROLLER =========
echo "👉 Tạo REST Controller đơn giản"
mkdir -p src/main/java/com/example/firebase
cat > src/main/java/com/example/firebase/HelloController.java <<'EOF'
package com.example.firebase;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("/")
    public String hello() {
        return "✅ Hello from Spring Boot running on Firebase/GCP!";
    }
}
EOF

# ========= STEP 5: CREATE DOCKERFILE =========
echo "👉 Tạo Dockerfile"
cat > Dockerfile <<'EOF'
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY . .
RUN ./mvnw package -DskipTests
CMD ["java", "-jar", "target/*.jar"]
EOF

# ========= STEP 6: DEPLOY TO CLOUD RUN =========
echo "👉 Build và deploy lên Cloud Run"
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME --project=$PROJECT_ID

gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --project=$PROJECT_ID

URL=$(gcloud run services describe $SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --project=$PROJECT_ID \
  --format='value(status.url)')

echo "✅ DONE! Spring Boot app đã chạy tại:"
echo "👉 $URL"
