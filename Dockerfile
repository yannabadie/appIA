# ──────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS base

# Ajoute Node 22 pour la CLI Codex
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends curl gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs git \
 && rm -rf /var/lib/apt/lists/*

# Crée un venv « /venv »
ENV VENV_PATH=/venv
RUN python -m venv $VENV_PATH
ENV PATH="$VENV_PATH/bin:$PATH"

WORKDIR /workspace
COPY requirements_jarvys_core.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements_jarvys_core.txt

# Copie le code après l’instal. des deps (meilleur cache)
COPY . .

RUN chmod +x jarvys_dev.sh

ENTRYPOINT ["bash", "./jarvys_dev.sh"]
