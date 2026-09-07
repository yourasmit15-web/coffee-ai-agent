#!/usr/bin/env bash
set -Eeuo pipefail

# One-command bootstrap for Coffee AI Agent on Google Cloud.
# Run this from Google Cloud Shell while authenticated to the target project.

PROJECT_ID="${PROJECT_ID:-coffee-ai-agent-507911}"
REGION="${REGION:-asia-south1}"
REPO="${GITHUB_REPOSITORY:-yourasmit15-web/coffee-ai-agent}"
POOL_ID="${WIF_POOL_ID:-github}"
PROVIDER_ID="${WIF_PROVIDER_ID:-github-provider}"
DEPLOYER_SA="${DEPLOYER_SA:-github-deployer}"

log() { printf '\n==> %s\n' "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

command -v gcloud >/dev/null 2>&1 || fail "gcloud is not installed. Run this from Google Cloud Shell."

ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n1)"
[ -n "$ACTIVE_ACCOUNT" ] || fail "No active Google account. Authenticate in Cloud Shell first."

gcloud config set project "$PROJECT_ID" >/dev/null

log "Enabling required APIs"
gcloud services enable \
  run.googleapis.com \
  aiplatform.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  serviceusage.googleapis.com \
  logging.googleapis.com

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
[ -n "$PROJECT_NUMBER" ] || fail "Could not resolve project number."

log "Preparing Cloud Build service identity"
BUILD_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${BUILD_SA}" \
  --role="roles/run.builder" \
  --quiet >/dev/null

log "Preparing GitHub Actions deployer service account"
if ! gcloud iam service-accounts describe "${DEPLOYER_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$DEPLOYER_SA" \
    --project "$PROJECT_ID" \
    --display-name="Coffee AI Agent GitHub Deployer"
fi

DEPLOYER_EMAIL="${DEPLOYER_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

# Roles needed for source deployment and Vertex AI access.
for ROLE in \
  roles/run.admin \
  roles/run.sourceDeveloper \
  roles/serviceusage.serviceUsageConsumer \
  roles/aiplatform.user \
  roles/logging.viewer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${DEPLOYER_EMAIL}" \
    --role="$ROLE" \
    --quiet >/dev/null
done

# The deployer must be allowed to act as the Cloud Run service identity.
gcloud iam service-accounts add-iam-policy-binding "$BUILD_SA" \
  --project "$PROJECT_ID" \
  --member="serviceAccount:${DEPLOYER_EMAIL}" \
  --role="roles/iam.serviceAccountUser" \
  --quiet >/dev/null

log "Creating GitHub OIDC workload identity pool/provider"
if ! gcloud iam workload-identity-pools describe "$POOL_ID" --project="$PROJECT_ID" --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL_ID" \
    --project="$PROJECT_ID" \
    --location=global \
    --display-name="GitHub Actions Pool"
fi

if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
    --project="$PROJECT_ID" \
    --location=global \
    --workload-identity-pool="$POOL_ID" \
    --display-name="GitHub Actions OIDC" \
    --issuer-uri="https://token.actions.githubusercontent.com/" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository == '${REPO}'"
fi

POOL_NAME="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}"
PROVIDER_NAME="${POOL_NAME}/providers/${PROVIDER_ID}"
PRINCIPAL="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${REPO}"

gcloud iam service-accounts add-iam-policy-binding "$DEPLOYER_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="$PRINCIPAL" \
  --quiet >/dev/null

log "Google Cloud bootstrap complete"
printf '\nCopy these four GitHub Actions repository variables exactly:\n\n'
printf 'GCP_PROJECT_ID=%s\n' "$PROJECT_ID"
printf 'GCP_REGION=%s\n' "$REGION"
printf 'WIF_PROVIDER=%s\n' "$PROVIDER_NAME"
printf 'WIF_SERVICE_ACCOUNT=%s\n' "$DEPLOYER_EMAIL"
printf '\nRepository: %s\nProject number: %s\n\n' "$REPO" "$PROJECT_NUMBER"
printf 'Next: add those four values under GitHub → Settings → Secrets and variables → Actions → Variables, then run the Deploy Coffee AI Agent workflow.\n'
