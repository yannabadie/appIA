FROM ghcr.io/openai/codex-universal:latest

# ── Bash, Python3 + Node.js 22 ─────────────────────────────────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        bash \
        curl \
        gnupg \
        ca-certificates \
        python3 \
        python3-pip \
        python3-venv \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . .

RUN sed -i 's/\r$//' jarvys_dev.sh \
 && chmod +x jarvys_dev.sh

ENTRYPOINT ["/bin/bash", "./jarvys_dev.sh"]
