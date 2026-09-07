param([Parameter(Mandatory=$true)][string]$ProjectId,[string]$Region="asia-south1")
gcloud config set project $ProjectId
gcloud services enable run.googleapis.com aiplatform.googleapis.com cloudbuild.googleapis.com
gcloud run deploy coffee-ai-agent --source ./backend --region $Region --allow-unauthenticated --set-env-vars "GOOGLE_GENAI_USE_VERTEXAI=TRUE,GOOGLE_CLOUD_PROJECT=$ProjectId,GOOGLE_CLOUD_LOCATION=global,COFFEE_AGENT_MODEL=gemini-2.5-flash,COFFEE_AGENT_EMBEDDING_MODEL=gemini-embedding-001"
