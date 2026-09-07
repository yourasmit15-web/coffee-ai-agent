#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="${1:?Usage: ./deploy-cloud-run.sh PROJECT_ID [REGION]}"
REGION="${2:-asia-south1}"
gcloud config set project "$PROJECT_ID"
gcloud services enable run.googleapis.com aiplatform.googleapis.com cloudbuild.googleapis.com
gcloud run deploy coffee-ai-agent --source ./backend --region "$REGION" --allow-unauthenticated --set-env-vars "GOOGLE_GENAI_USE_VERTEXAI=TRUE,GOOGLE_CLOUD_PROJECT=$PROJECT_ID,GOOGLE_CLOUD_LOCATION=global,COFFEE_AGENT_MODEL=gemini-2.5-flash,COFFEE_AGENT_EMBEDDING_MODEL=gemini-embedding-001"
