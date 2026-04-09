# VPS Gateway Deployment

This stack is intended for a small VPS where Hermes runs as an always-on
gateway for Signal and Telegram, with GitHub and Google Workspace access.

## What It Includes

- `Dockerfile.slim`
  Hermes with `pty`, `mcp`, `cron`, `messaging`, and Google Workspace client deps
- Google client libraries for the bundled `google-workspace` skill
- `gh`, `git`, and `ripgrep` for GitHub-heavy workflows
- `Dockerfile.signal-cli`
  A separate Signal daemon sidecar
- `docker-compose.vps.yml`
  Base Compose v2.4 file for Hermes itself
- `docker-compose.signal.yml`
  Optional Signal overlay for older `docker-compose` releases

## Why Signal Stays Separate

The slim image now includes the gateway pieces needed for Telegram and Google
Workspace. Signal still requires a separate `signal-cli` daemon, and that
daemon requires Java. Keeping it separate avoids bloating the main Hermes
image and lets Telegram-only deployments run without a dormant Signal service.

## First-Time Setup

1. Create an env file beside the compose file:

```bash
cp .env.example .env
```

2. Set your provider and messaging credentials in `.env`.

Copilot example:

```bash
HERMES_INFERENCE_PROVIDER=copilot
HERMES_MODEL=gpt-5.4
GH_TOKEN=gho_xxx
```

Codex example:

```bash
HERMES_INFERENCE_PROVIDER=openai-codex
HERMES_MODEL=gpt-5.4-codex
```

For Codex, complete device-code login once:

```bash
docker-compose -f docker-compose.vps.yml run --rm hermes model
```

The resulting auth state is stored under `./data`.

3. Start Hermes for Telegram-first usage:

```bash
docker-compose -f docker-compose.vps.yml up -d --build
```

4. If you later want Signal, link the sidecar once:

```bash
docker-compose -f docker-compose.vps.yml -f docker-compose.signal.yml run --rm signal-cli link -n HermesAgent
```

Then set `SIGNAL_ACCOUNT=+15551234567` in `.env`.

5. Start Hermes with the Signal overlay:

```bash
docker-compose -f docker-compose.vps.yml -f docker-compose.signal.yml up -d --build
```

## Notes

- Hermes stores all runtime state in `./data`.
- Signal session state is stored in `./signal-data`.
- `SIGNAL_HTTP_URL` is only wired automatically when you include `docker-compose.signal.yml`.
- The compose file uses `mem_limit` because old `docker-compose` versions do
  not support the newer `deploy.resources` syntax reliably.
