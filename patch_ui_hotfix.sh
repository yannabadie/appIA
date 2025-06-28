#!/bin/bash
set -e

echo "=== [PATCH UI HOTFIX] Jarvis Frontend ==="

# 1. Ajoute index.css si absent
cat > frontend/src/index.css <<EOF
body {
  background: #1a1c23;
  font-family: 'Segoe UI', 'Arial', sans-serif;
  color: #e0ffe9;
}
input, select, button {
  font-family: inherit;
}
::-webkit-scrollbar {
  width: 10px;
  background: #23223b;
}
::-webkit-scrollbar-thumb {
  background: #1affac66;
  border-radius: 8px;
}
EOF

# 2. Patch main.tsx pour importer index.css
cat > frontend/src/main.tsx <<EOF
import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import JarvisApp from "./JarvisApp";

createRoot(document.getElementById("root")).render(<JarvisApp />);
EOF

echo "✅ UI patch appliqué (index.css créé, import corrigé)."
echo "Relance simplement npm run dev dans frontend."
