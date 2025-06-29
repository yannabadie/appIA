FROM ghcr.io/openai/codex-universal:latest

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    VENV_PATH=/opt/venv

# ── Tools ──────────────────────────────────────────────────────────────────
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends python3-venv curl && \
    rm -rf /var/lib/apt/lists/* && \
    python -m venv $VENV_PATH && \
    $VENV_PATH/bin/pip install --upgrade pip

# Copy code first to leverage cache
WORKDIR /workspace
COPY requirements_jarvys_core.txt .

RUN . $VENV_PATH/bin/activate && \
    pip install --no-cache-dir -r requirements_jarvys_core.txt

# Copy the rest of the repo
COPY . .

ENV PATH="$VENV_PATH/bin:$PATH"

ENTRYPOINT ["bash", "./jarvys_dev.sh"]
