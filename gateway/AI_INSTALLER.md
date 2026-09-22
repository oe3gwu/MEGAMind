# AI installer — LiteLLM HTTP gateway (Docker Compose)

Copy everything below the line into an AI agent (Cursor, etc.). The agent installs the same stack as the manual guide in [`INSTALL.md`](INSTALL.md). Prefer using this repo’s `gateway/` folder when it is already checked out.

---

Install LiteLLM as a local HTTP gateway on this system **using Docker Compose only**. No database.

## Goal

- Local HTTP only (no HTTPS/TLS on the LAN listener)
- Bind `0.0.0.0` so LAN devices (retro / MEGA65) can reach it
- Upstream over HTTPS via operator-supplied `UPSTREAM_API_BASE` (OpenAI-compatible `/v1`)
- OpenAI-compatible path: `/v1/chat/completions`
- Default model: `Qwen/Qwen3.8-27B-FP8`
- No Postgres/Redis/DB — LiteLLM proxy container only
- Autostart via Docker `restart: unless-stopped`

## Prefer existing files

If this repository’s `gateway/` directory is present, **reuse** `docker-compose.yml`, `config.yaml`, and `.env.sample` instead of rewriting them. Only create those files when missing. Always create/update `.env` from `.env.sample` with operator secrets.

## Work steps

1. Check Docker and Docker Compose. Install them if missing.
2. Working directory: this repo’s `gateway/` folder, or e.g. `/opt/litellm-gateway/` if installing elsewhere.
3. Ensure `docker-compose.yml` exists (create only if missing). Prefer reading secrets from a `.env` file; do not hard-code real API keys or upstream URLs into committed files:

```yaml
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: litellm-gateway
    restart: unless-stopped
    ports:
      - "4000:4000"
    environment:
      - LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY:-retrosystem}
      - UPSTREAM_API_KEY=${UPSTREAM_API_KEY}
      - UPSTREAM_API_BASE=${UPSTREAM_API_BASE}
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    command: ["--config", "/app/config.yaml", "--host", "0.0.0.0", "--port", "4000"]
```

4. Ensure `config.yaml` exists (create only if missing):

```yaml
model_list:
  - model_name: Qwen/Qwen3.8-27B-FP8
    litellm_params:
      model: openai/Qwen/Qwen3.8-27B-FP8
      api_base: os.environ/UPSTREAM_API_BASE
      api_key: os.environ/UPSTREAM_API_KEY

litellm_settings:
  drop_params: true
```

5. Create `.env` from `.env.sample` (ask the operator for missing values):
   - `LITELLM_MASTER_KEY` — Bearer token for LAN clients (default `retrosystem` if the operator agrees)
   - `UPSTREAM_API_BASE` — OpenAI-compatible upstream base URL, e.g. `https://api.example.com/v1`
   - `UPSTREAM_API_KEY` — upstream API key supplied by the operator
6. Start: `docker compose up -d`
7. Verify compose interpolation: `docker compose config` must show non-empty `UPSTREAM_API_BASE` and `UPSTREAM_API_KEY` in the service environment.
8. Verify API:

```bash
curl -sS -X POST "http://127.0.0.1:4000/v1/chat/completions" \
  -H "Authorization: Bearer retrosystem" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3.8-27B-FP8",
    "messages": [{"role": "user", "content": "ping"}],
    "max_tokens": 16
  }'
```

(Use the same Bearer value as `LITELLM_MASTER_KEY`.)

## Final report

Print: host LAN IP, port `4000`, path `/v1/chat/completions`, model name, compose directory path, env vars set (names only, never print secret values), and a short curl result summary.

## Client settings (MEGAMind / MEGA65)

- Host: Docker host LAN IP or DNS name
- Port: `4000`
- Path: `/v1/chat/completions`
- Token: `LITELLM_MASTER_KEY`
- Model: `Qwen/Qwen3.8-27B-FP8`
- HTTP only (no HTTPS)
