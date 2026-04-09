# VPS Gateway Deployment

This stack is intended for a small VPS where Hermes runs as an always-on
gateway for Signal and Telegram, with GitHub and Google Workspace access.

## What It Includes

- `Dockerfile.gateway-vps`
  Hermes with `pty`, `mcp`, `cron`, and `messaging`
- Google client libraries for the bundled `google-workspace` skill
- `gh`, `git`, and `ripgrep` for GitHub-heavy workflows
- `Dockerfile.signal-cli`
  A separate Signal daemon sidecar
- `docker-compose.vps.yml`
  Compose v2.4 file that works with older `docker-compose` releases

## Why Not Reuse `Dockerfile.slim`

The existing slim image intentionally omits the `messaging` extra, so it
cannot run Telegram. Signal also requires a separate `signal-cli` daemon.

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

3. If using Signal, link the sidecar once:

```bash
docker-compose -f docker-compose.vps.yml run --rm signal-cli link -n HermesAgent
```

Then set `SIGNAL_ACCOUNT=+15551234567` in `.env`.

4. Start the stack:

```bash
docker-compose -f docker-compose.vps.yml up -d --build
```

## Notes

- Hermes stores all runtime state in `./data`.
- Signal session state is stored in `./signal-data`.
- `SIGNAL_HTTP_URL` is wired to the sidecar automatically.
- The compose file uses `mem_limit` because old `docker-compose` versions do
  not support the newer `deploy.resources` syntax reliably.
