#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
  set -- daemon --http 0.0.0.0:8080
fi

cmd="$1"

if [ "$cmd" = "link" ] || [ "$cmd" = "listAccounts" ]; then
  exec signal-cli "$@"
fi

account="${SIGNAL_CLI_ACCOUNT:-${SIGNAL_ACCOUNT:-}}"
if [ -z "$account" ]; then
  echo "SIGNAL_CLI_ACCOUNT or SIGNAL_ACCOUNT is required for signal-cli daemon commands" >&2
  exit 1
fi

exec signal-cli --account "$account" "$@"
