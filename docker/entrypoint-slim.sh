#!/bin/bash
# Slim-image entrypoint: bootstrap config files into the mounted volume, then run hermes.
# The slim image does not use s6-overlay — this script is the direct ENTRYPOINT.
set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="/opt/hermes"
export HOME="$HERMES_HOME/home"

exec_as_runtime_user() {
    if [ "$(id -u)" != "0" ]; then
        exec "$@"
    fi

    exec python3 - "$@" <<'PY'
import os
import pwd
import sys

target = pwd.getpwnam("hermes")
os.environ["HOME"] = os.environ.get("HOME") or os.path.join(
    os.environ.get("HERMES_HOME", "/opt/data"), "home"
)
os.setgid(target.pw_gid)
os.initgroups(target.pw_name, target.pw_gid)
os.setuid(target.pw_uid)
os.execvp(sys.argv[1], sys.argv[1:])
PY
}

# Create essential directory structure.
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}

# .env
if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env"
fi

# config.yaml
if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    cp "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml"
fi

# SOUL.md
if [ ! -f "$HERMES_HOME/SOUL.md" ]; then
    cp "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md"
fi

# Install-method stamp (read by hermes status)
printf 'docker\n' > "$HERMES_HOME/.install_method" 2>/dev/null || true

# auth.json: bootstrap from env on first boot only. The [ ! -f ] guard
# avoids clobbering rotated refresh tokens on container restart.
if [ ! -f "$HERMES_HOME/auth.json" ] && [ -n "${HERMES_AUTH_JSON_BOOTSTRAP:-}" ]; then
    printf '%s' "$HERMES_AUTH_JSON_BOOTSTRAP" > "$HERMES_HOME/auth.json"
    chmod 600 "$HERMES_HOME/auth.json"
fi

# Sync bundled skills (manifest-based so user edits are preserved)
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py"
fi

if [ "$(id -u)" = "0" ]; then
    chown -R hermes:hermes "$HERMES_HOME" 2>/dev/null || \
        echo "[entrypoint-slim] Warning: chown $HERMES_HOME failed; continuing"
fi

# Final exec: if the first arg resolves to an executable on PATH, run it
# directly (needed for sandbox containers running `sleep infinity`).
# Otherwise treat args as a hermes subcommand.
if [ $# -gt 0 ] && command -v "$1" >/dev/null 2>&1; then
    exec_as_runtime_user "$@"
fi
exec_as_runtime_user hermes "$@"
