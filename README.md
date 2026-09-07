# Coffee AI Agent

A personalized coffee-shop assistant built with Google ADK, Gemini on Vertex AI, a lightweight RAG layer, and a React/Vite chat UI.

## Features
- Personalized customer profiles and recommendations
- RAG over coffee menu and FAQs using Gemini embeddings
- Order drafting without payment or real order submission
- Google ADK API server
- Cloud Run deployment configuration
- React/Vite frontend
- Pytest and GitHub Actions CI

## Architecture
Customer → React UI → ADK API → Gemini/Vertex AI → RAG + recommendation tools

## Quick start
1. Install Python 3.12+, Node.js 20+, Google Cloud CLI, and Google ADK.
2. Authenticate with `gcloud auth login` and `gcloud auth application-default login`.
3. Configure Vertex AI environment variables from `.env.example`.
4. Start the backend with `adk api_server --host 0.0.0.0 --port 8080` from `backend`.
5. Start the frontend with `npm install && npm run dev` from `frontend`.

## Cloud Run
Use `deploy-cloud-run.ps1` on PowerShell or `deploy-cloud-run.sh` on Linux/macOS. The deployment uses Cloud Run source deployment and Vertex AI.

## Production notes
The included RAG index is intentionally lightweight and in-memory for a runnable starter. For production, move vectors to a managed vector store such as Cloud SQL PostgreSQL with pgvector or Vertex AI Vector Search, and move customer profiles to persistent storage.

Do not commit API keys, credentials, or `.env` files.
