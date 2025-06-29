FROM ghcr.io/openai/codex-universal:latest

WORKDIR /workspace
COPY . .

# Les clés seront injectées au moment du docker run
ENV OPENAI_API_KEY=""
ENV GITHUB_TOKEN=""

RUN chmod +x jarvys_dev.sh
CMD ["./jarvys_dev.sh"]
