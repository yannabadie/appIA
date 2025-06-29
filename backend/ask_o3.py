import argparse, os, json, openai
openai.api_key = os.getenv("OPENAI_API_KEY")

PROMPT_TMPL = """
You are an autonomous planner for a GitHub repository.
Context snippets (supabase RAG):
<<<CONTEXT>>>
{context}
<<<END>>>

GitHub issue to solve:
TITLE: {title}
BODY:
{body}

Produce JSON with:
- codex_prompt  : French/English prompt for OpenAI Codex CLI to implement the solution.
- test_cmd      : shell command to verify (pytest, npm test...)

Return ONLY valid JSON.
"""

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--title"), p.add_argument("--body"), p.add_argument("--context")
    args = p.parse_args()
    res = openai.ChatCompletion.create(
        model="gpt-4o3",
        messages=[
            {"role":"system","content":"You output ONLY JSON."},
            {"role":"user","content":PROMPT_TMPL.format(**vars(args))}
        ],
        temperature=0.3
    )
    print(res.choices[0].message.content.strip())

if __name__ == "__main__":
    main()
