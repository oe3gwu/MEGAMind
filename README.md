# MEGAMind

OpenAI-compatible **inference chat** for **MEGA65 BASIC65**, using [Mega-IP](https://github.com/mega65-c65/mega-ip) (`eth.bin`).

The UI follows the Mega-IP IRC demo style: 80-column chat, reverse video header, slash commands, DHCP or manual network setup.

Header: **MEGAMind - Inference Chat**

| Document | Purpose |
|----------|---------|
| [This README](README.md) | Overview, BASIC program, usage, build |
| [gateway/INSTALL.md](gateway/INSTALL.md) | Manual Docker Compose LiteLLM install |
| [litellm-gateway-prompt.txt](litellm-gateway-prompt.txt) | Prompt for an AI agent to install the gateway |

Repository: https://github.com/oe3gwu/MEGAMind

---

## Important: HTTP only (no TLS)

Mega-IP has **no TLS**. MEGAMind speaks **HTTP/1.0** with `Authorization: Bearer …` to a LAN gateway (typically LiteLLM).

Default endpoint shape: `http://<host>:4000/v1/chat/completions`.

---

## Layout

```
basic/megamind.bas          — BASIC65 source (chat client)
config/megamind.cfg         — default API config (shipped on disk)
vendor/eth.bin              — Mega-IP library
tools/build_d81.sh          — petcat + c1541 → D81
tools/run_xemu.sh           — xemu MEGA65 launcher
gateway/                    — LiteLLM Docker Compose install
  docker-compose.yml
  config.yaml
  .env.example
  INSTALL.md
litellm-gateway-prompt.txt  — AI installer prompt (English)
target/                     — build outputs (gitignored)
```

---

## BASIC program (`basic/megamind.bas`)

Single-file **BASIC65** client. High-level structure:

| Lines (approx.) | Role |
|-----------------|------|
| 140–370 | Init: load `eth.bin` at `$42000`, screen, network, config, DNS, enter chat |
| 410–440 | Main loop: keyboard + Mega-IP poll |
| 800–1180 | Screen: header, model bar, chat window, input line |
| 1800–2230 | Keyboard, slash commands, help |
| 3470–3880 | Network: DHCP or manual IP/gateway/mask/DNS |
| 3890–4540 | Line editor prompts (masked API key) |
| 5000–5450 | DNS resolve, TCP connect/retry/close |
| 6000–6980 | Chat completion: HTTP POST, stream-parse `"content":"…"` |
| 7200–7840 | Load/save `megamind.cfg`, keep/change credentials |
| 7900–8564 | PETSCII sanitize, JSON escape/send, length calc |

### Behaviour notes

- Loads Mega-IP with `bload"eth.bin",p($42000),r` and calls `sys` entry points for DHCP, DNS, TCP.
- Keeps a short rolling chat history (`mh=10`) for multi-turn `messages[]`.
- BASIC65 strings are short (~255); the body is **never** held as one giant string — JSON is sent in chunks, and the assistant reply is **stream-parsed** from the HTTP body.
- Only printable/letter/punct PETSCII is kept for display and JSON (colour/graphics codes dropped).

### Configuration file (`megamind.cfg`)

SEQ file on the D81:

```
HOST=litellm.chronolink.lan
PORT=4000
PATH=/v1/chat/completions
TOKEN=retrosystem
MODEL=Qwen/Qwen3.8-27B-FP8
```

Startup:

1. **[D]HCP** or **[M]anual** network  
2. Load `megamind.cfg` (built-in defaults if missing)  
3. **[K]eep** settings or **[C]hange** API credentials  
4. After a change: **[S]ave** or **[N]ot now**  
5. DNS resolve → chat UI  

---

## Usage

### On real MEGA65 hardware

1. Build or obtain `target/megamind.d81` (see [Build](#build)).
2. Copy the D81 to SD (or transfer another way).
3. Ethernet connected; DNS (or reachable host) for your LiteLLM gateway.
4. `LOAD"MEGAMIND"` then `RUN` (or your usual autoload).
5. Choose DHCP/manual, keep or change API settings, then type prompts in the chat line.

Point `HOST`/`PORT`/`TOKEN`/`MODEL` at your [gateway](gateway/INSTALL.md).

### In xemu

```bash
./tools/build_d81.sh
./tools/run_xemu.sh
# with Ethernet tap:
ETHERTAP=tap0 ./tools/run_xemu.sh
```

### Slash commands

| Command | Action |
|---------|--------|
| `/help` | Command list |
| `/model name` | Set model |
| `/host name` | Set API host (re-resolve DNS) |
| `/port n` | Set TCP port |
| `/path /v1/...` | Set request path |
| `/token` | Set API key (masked input) |
| `/config` | Re-run credential prompts |
| `/save` | Write `megamind.cfg` |
| `/clear` | Clear chat history |
| `/status` | Show config (key masked) |
| `/quit` | Exit |

Type a normal line (no leading `/`) to send a user message to the model. The status line shows **Waiting for model...** until the reply is streamed.

### Session side panel

Right column: message count, truncated model, host, and port.

---

## Build

Needs VICE tools `petcat` and `c1541`:

```bash
./tools/build_d81.sh
```

Produces `target/megamind.d81` containing `megamind`, `eth.bin`, and `megamind.cfg`.

Optional overrides: `PETCAT=/path/to/petcat` `C1541=/path/to/c1541`.

---

## LiteLLM gateway (for LAN HTTP)

MEGAMind needs an HTTP OpenAI-compatible endpoint. This repo ships two install paths:

### A) Manual Docker Compose

See **[gateway/INSTALL.md](gateway/INSTALL.md)**.

Short version:

```bash
cd gateway
cp .env.example .env   # set LLM2GO_API_KEY
docker compose up -d
```

Smoke test:

```bash
curl -sS -X POST "http://127.0.0.1:4000/v1/chat/completions" \
  -H "Authorization: Bearer retrosystem" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3.8-27B-FP8","messages":[{"role":"user","content":"ping"}],"max_tokens":16}'
```

### B) AI installer

Feed an agent (Cursor, etc.) the prompt in **[litellm-gateway-prompt.txt](litellm-gateway-prompt.txt)**. It instructs the agent to install the same HTTP-only LiteLLM Compose stack, verify with `curl`, and report LAN IP / port / path for MEGAMind.

Upstream defaults to `https://llm2go-api.scch.at/v1`; override in `config.yaml` / `.env` as needed. **Do not commit real API keys.**

---

## MEGAMind ↔ gateway settings

| `megamind.cfg` | Typical value |
|----------------|---------------|
| `HOST` | Docker host LAN IP or DNS name |
| `PORT` | `4000` |
| `PATH` | `/v1/chat/completions` |
| `TOKEN` | `LITELLM_MASTER_KEY` (e.g. `retrosystem`) |
| `MODEL` | `Qwen/Qwen3.8-27B-FP8` |

---

## Credits

- Networking: [Mega-IP](https://github.com/mega65-c65/mega-ip)  
- Proxy: [LiteLLM](https://github.com/BerriAI/litellm)
