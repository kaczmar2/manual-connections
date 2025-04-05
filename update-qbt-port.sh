#!/usr/bin/env bash

# qBittorrent Web UI credentials
QB_HOST="localhost"
QB_PORT="8080"
QB_USERNAME="admin"
QB_PASSWORD="yourpassword"

# Port passed as first argument
PORT="$1"

if [[ -z "$PORT" || ! "$PORT" =~ ^[0-9]+$ ]]; then
  echo "error: invalid or missing port argument"
  exit 1
fi

# Authenticate and capture full response headers
LOGIN_RESPONSE=$(curl -s -i \
  --header "Referer: http://$QB_HOST:$QB_PORT" \
  --data "username=$QB_USERNAME&password=$QB_PASSWORD" \
  "http://$QB_HOST:$QB_PORT/api/v2/auth/login")

# Extract cookie (case-insensitive header match)
COOKIE=$(echo "$LOGIN_RESPONSE" | grep -i '^set-cookie:' | sed -n 's/^[Ss]et-[Cc]ookie: \(SID=[^;]*\);.*/\1/p')

if [[ -z "$COOKIE" ]]; then
  echo "error: failed to authenticate with qBittorrent"
  exit 1
fi

# Set the new listening port using Web API
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --cookie "$COOKIE" \
  --data-urlencode "json={\"listen_port\":$PORT}" \
  "http://$QB_HOST:$QB_PORT/api/v2/app/setPreferences")

if [[ "$RESPONSE_CODE" == "200" ]]; then
  echo "success"
else
  echo "error: failed to update qBittorrent port"
  exit 1
fi
