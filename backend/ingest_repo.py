# backend/ingest_repo.py
import os, pathlib, openai, json
from supabase import create_client

openai.api_key  = os.environ["OPENAI_API_KEY"]
sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_KEY"])
MODEL = "text-embedding-3-small"

def embed(txt: str) -> list[float]:
    return openai.Embedding.create(input=[txt], model=MODEL)["data"][0]["embedding"]

for path in pathlib.Path(".").rglob("*.py"):
    text = path.read_text(encoding="utf-8")[:1200]        # tronque à 1 200 car.
    vec  = embed(text)
    sb.table("chunks").insert({
        "text":       text,
        "file_path":  str(path),
        "embedding":  vec
    }).execute()

print("🎉 Ingestion terminée")
