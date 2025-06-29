FROM ghcr.io/openai/codex-universal:latest

WORKDIR /workspace
COPY . .
COPY requirements_jarvys_core.txt .

RUN pip install --no-cache-dir -r requirements_jarvys_core.txt
# Les clés seront injectées au moment du docker run
ENV OPENAI_API_KEY=""
ENV GITHUB_TOKEN=""

RUN chmod +x jarvys_dev.sh
CMD ["./jarvys_dev.sh"]
