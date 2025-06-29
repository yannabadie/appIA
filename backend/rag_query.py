import os, sys, json, openai, hashlib, pathlib, datetime
from supabase import create_client, Client
from tiktoken import encoding_for_model

openai.api_key = os.getenv("OPENAI_API_KEY")
SUPABASE_URL  = os.getenv("SUPABASE_URL")
SUPABASE_KEY  = os.getenv("SUPABASE_KEY")
sb: Client    = create_client(SUPABASE_URL, SUPABASE_KEY)

MODEL = "text-embedding-3-small"
ENC   = encoding_for_model(MODEL)

def embed(text: str) -> list[float]:
    return openai.Embedding.create(input=[text], model=MODEL)["data"][0]["embedding"]

def similarity(a, b):  # cosine
    import numpy as np
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

def top_k(query_vec, k=5):
    rows = sb.rpc('match_rag', {
        "query_embedding": query_vec,
        "match_threshold": 0.78,
        "match_count": k
    }).execute()
    return [r['text'] for r in rows.data] if rows.data else []

query = sys.argv[1]
q_vec = embed(query)
ctx   = "\n---\n".join(top_k(q_vec))
print(ctx)
