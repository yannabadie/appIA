# base image plus légère qu’openai/codex-universal pour builder rapidement
FROM python:3.12-slim AS base

# ── OS deps + Node 22 ─────────────────────────────────────
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends curl gnupg git ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# ── venv isolé ────────────────────────────────────────────
ENV VENV_PATH=/venv
RUN python -m venv $VENV_PATH
ENV PATH="$VENV_PATH/bin:$PATH"

# ── Python deps ───────────────────────────────────────────
WORKDIR /workspace
COPY requirements_jarvys_core.txt .
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements_jarvys_core.txt

# ── Code + script exécutable ──────────────────────────────
COPY . .
RUN chmod +x jarvys_dev.sh && sed -i 's/\r$//' jarvys_dev.sh

ENTRYPOINT ["bash", "./jarvys_dev.sh"]
