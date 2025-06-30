-- Extension pgvector
create extension if not exists vector;

-- Table pour stocker les passages
create table if not exists public.chunks (
  id        uuid primary key default gen_random_uuid(),
  text      text,
  file_path text,
  embedding vector(1536)
);

-- Index HNSW
create index if not exists chunks_embedding_idx
  on public.chunks using hnsw (embedding vector_l2_ops);

-- Fonction de similarité
create or replace function public.match_rag(
  query_embedding vector(1536),
  match_threshold float,
  match_count     int
)
returns table(id uuid, text text, similarity float)
language sql stable as $$
  select id,
         text,
         1 - (embedding <=> query_embedding) as similarity
  from public.chunks
  where embedding <=> query_embedding < match_threshold
  order by similarity desc
  limit match_count;
$$;
