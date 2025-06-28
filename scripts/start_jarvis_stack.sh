#!/bin/bash
echo "=== [JARVIS AI] Lancement stack ==="
cd backend && uvicorn main:app --host 0.0.0.0 --port 8000 &
BACK_PID=$!
cd ../frontend && npm run dev &
FRONT_PID=$!
wait $BACK_PID $FRONT_PID
