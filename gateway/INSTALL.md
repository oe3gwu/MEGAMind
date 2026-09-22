# Manual LiteLLM gateway install (Docker Compose)

Install a local **HTTP-only** LiteLLM proxy so MEGAMind (MEGA65 + Mega-IP) can call an OpenAI-compatible chat API. Mega-IP has **no TLS**, so the LAN side must stay plain HTTP.

Prefer an agent? Paste **[AI_INSTALLER.md](AI_INSTALLER.md)** into Cursor (or similar). Overview of this folder: **[README.md](README.md)**.

## Requirements

- Docker Engine
- Docker Compose v2 (`docker compose`)

```bash
docker --version
docker compose version
```

## Layout

```
gateway/
  README.md           — folder overview + env var table
  INSTALL.md          — this manual install
  AI_INSTALLER.md     — AI agent installer prompt
  docker-compose.yml
  config.yaml
  .env.sample         → copy to .env
```

You may install anywhere, e.g. `/opt/litellm-gateway/` or this `gateway/` folder.

## Environment variables

Copy the sample and edit:

```bash
cd gateway   # or your install directory
cp .env.sample .env
```

| Variable | Example | Used by |
|----------|---------|---------|
| `LITELLM_MASTER_KEY` | `retrosystem` | Compose → LiteLLM master key; MEGAMind `TOKEN=` |
| `UPSTREAM_API_BASE` | `https://api.example.com/v1` | `config.yaml` → `api_base: os.environ/UPSTREAM_API_BASE` |
| `UPSTREAM_API_KEY` | `sk-…` | `config.yaml` → `api_key: os.environ/UPSTREAM_API_KEY` |

Compose substitutes `${…}` from `.env` into the container environment. Confirm:

```bash
docker compose config
```

`UPSTREAM_API_BASE` and `UPSTREAM_API_KEY` must appear non-empty under `services.litellm.environment`.

## Steps

### 1. Configure secrets

Edit `.env` as above (`UPSTREAM_API_BASE`, `UPSTREAM_API_KEY`, optional `LITELLM_MASTER_KEY`).

### 2. Review `config.yaml`

Upstream URL and key come only from the environment (no hardcoded provider URL).  
Default model name (must match MEGAMind `MODEL=`): `Qwen/Qwen3.8-27B-FP8`

Change `model_name` / `model` in `config.yaml` if your provider’s model id differs.

### 3. Start

```bash
docker compose up -d
docker compose ps
docker compose logs -f litellm
```

### 4. Smoke test

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

Use the same Bearer token as `LITELLM_MASTER_KEY` in `.env`.

### 5. Point MEGAMind at the gateway

On the MEGA65 / disk `megamind.cfg` (or via `/config` in chat):

| Setting | Example |
|---------|---------|
| `HOST`  | LAN IP or hostname of the Docker host |
| `PORT`  | `4000` |
| `PATH`  | `/v1/chat/completions` |
| `TOKEN` | same as `LITELLM_MASTER_KEY` |
| `MODEL` | `Qwen/Qwen3.8-27B-FP8` |

DNS must resolve `HOST` from the MEGA65 (or use a raw IP as host if Mega-IP accepts it).

## Operations

```bash
docker compose pull && docker compose up -d   # update image
docker compose down                           # stop
```

The service binds `0.0.0.0:4000` and uses `restart: unless-stopped` for autostart after reboot.

## Notes

- No Postgres/Redis — proxy only.
- Upstream traffic is HTTPS; LAN clients use HTTP.
- Do not commit `.env` with real API keys.
