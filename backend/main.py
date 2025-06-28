from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from agent_core import agent_query
import uvicorn

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"]
)

@app.post("/ask")
async def ask(request: Request):
    data = await request.json()
    prompt = data.get("prompt", "")
    llm = data.get("llm", "auto")
    try:
        response = agent_query(prompt, llm)
        return {"response": response}
    except Exception as e:
        return {"response": f"[Erreur backend]: {e}"}

@app.get("/history")
def history():
    return {"history": []}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
