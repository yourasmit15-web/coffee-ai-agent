from pathlib import Path
import json, os
import numpy as np
from google import genai
from google.genai.types import EmbedContentConfig

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "knowledge.json"
_client = None
_vectors = None
_records = None

def _client_or_create():
    global _client
    if _client is None:
        _client = genai.Client(vertexai=True, project=os.environ.get("GOOGLE_CLOUD_PROJECT"), location=os.environ.get("GOOGLE_CLOUD_LOCATION", "global"))
    return _client

def _load():
    global _records
    if _records is None:
        _records = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    return _records

def _embed(text, task):
    response = _client_or_create().models.embed_content(model=os.environ.get("COFFEE_AGENT_EMBEDDING_MODEL", "gemini-embedding-001"), contents=text, config=EmbedContentConfig(task_type=task, output_dimensionality=768))
    return np.asarray(response.embeddings[0].values, dtype=np.float32)

def _ensure_index():
    global _vectors
    records = _load()
    if _vectors is None:
        _vectors = np.vstack([_embed(r["content"], "RETRIEVAL_DOCUMENT") for r in records])
    return records, _vectors

def search(query, top_k=4):
    records, vectors = _ensure_index()
    q = _embed(query, "RETRIEVAL_QUERY")
    scores = vectors @ q / (np.linalg.norm(vectors, axis=1) * np.linalg.norm(q) + 1e-8)
    ids = np.argsort(scores)[::-1][:top_k]
    return [{**records[i], "score": round(float(scores[i]), 4)} for i in ids]
