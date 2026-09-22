# LiteLLM gateway for MEGAMind

HTTP-only OpenAI-compatible proxy for MEGA65 / Mega-IP (**no TLS** on the LAN side).

| Path | What |
|------|------|
| **[INSTALL.md](INSTALL.md)** | Manual Docker Compose install |
| **[AI_INSTALLER.md](AI_INSTALLER.md)** | Prompt to paste into an AI agent (installs the same stack) |
| `docker-compose.yml` | Compose service |
| `config.yaml` | LiteLLM model routing (`os.environ/…`) |
| `.env.sample` | Template → copy to `.env` |

## Environment variables (`.env`)

| Variable | Required | Purpose |
|----------|----------|---------|
| `LITELLM_MASTER_KEY` | yes (default `retrosystem`) | Bearer token MEGAMind sends (`TOKEN=` in `megamind.cfg`) |
| `UPSTREAM_API_BASE` | yes | Upstream OpenAI-compatible base URL, e.g. `https://api.example.com/v1` |
| `UPSTREAM_API_KEY` | yes | Upstream API key |

`config.yaml` reads the upstream values via LiteLLM’s `os.environ/UPSTREAM_API_BASE` and `os.environ/UPSTREAM_API_KEY`. Docker Compose injects them from `.env` into the container.

Quick check after editing `.env`:

```bash
docker compose config   # must show UPSTREAM_* populated under environment
```
