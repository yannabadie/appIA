# ────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS base

#################################################################
# 1. Outils système + Node 22 + Git + GitHub CLI
#################################################################
RUN apt-get update -y && \
    # curl + gnupg requis pour NodeSource ET GitHub CLI
    apt-get install -y --no-install-recommends curl gnupg && \
    \
    # ── Node.js 22 (Codex CLI a besoin de npm) ────────────────
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    \
    # ── GitHub CLI (gh) dépôt officiel ────────────────────────
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) \
          signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
          https://cli.github.com/packages stable main" \
          | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    \
    # ── Installation des paquets ──────────────────────────────
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        nodejs git gh && \
    \
    # Nettoyage
    rm -rf /var/lib/apt/lists/*

#################################################################
# 2. Environnement Python isolé (/venv)
#################################################################
ENV VENV_PATH=/venv
RUN python -m venv $VENV_PATH
ENV PATH="$VENV_PATH/bin:$PATH"

#################################################################
# 3. Dépendances Python
#################################################################
WORKDIR /workspace
COPY requirements_jarvys_core.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements_jarvys_core.txt

#################################################################
# 4. Code source + droits d’exécution
#################################################################
COPY . .
RUN chmod +x jarvys_dev.sh

ENTRYPOINT ["bash", "./jarvys_dev.sh"]
