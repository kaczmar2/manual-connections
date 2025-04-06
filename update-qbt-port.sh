#!/bin/bash

QB_HOST="localhost"
QB_PORT="8080"
QB_USERNAME="admin"
QB_PASSWORD="yourpassword"
INTERFACE="pia"
PORT="$1"

if [[ -z "$PORT" || ! "$PORT" =~ ^[0-9]+$ ]]; then
  echo "error: invalid or missing port argument"
  exit 1
fi

# Wait until qBittorrent Web UI is available
MAX_WAIT=30
for ((i=1; i<=MAX_WAIT; i++)); do
  if curl -s "http://$QB_HOST:$QB_PORT/api/v2/app/version" > /dev/null; then
    break
  fi
  echo "Waiting for qBittorrent Web UI... ($i/$MAX_WAIT)"
  sleep 1
done

# Authenticate
LOGIN_RESPONSE=$(curl -s -i \
  --header "Referer: http://$QB_HOST:$QB_PORT" \
  --data "username=$QB_USERNAME&password=$QB_PASSWORD" \
  "http://$QB_HOST:$QB_PORT/api/v2/auth/login")

COOKIE=$(echo "$LOGIN_RESPONSE" | grep -i '^set-cookie:' | sed -n 's/^[Ss]et-[Cc]ookie: \(SID=[^;]*\);.*/\1/p')

if [[ -z "$COOKIE" ]]; then
  echo "error: failed to authenticate with qBittorrent"
  exit 1
fi

# Set listening port and interface
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --cookie "$COOKIE" \
  --data-urlencode "json={\"listen_port\":$PORT,\"current_network_interface\":\"$INTERFACE\"}" \
  "http://$QB_HOST:$QB_PORT/api/v2/app/setPreferences")

if [[ "$RESPONSE" == "200" ]]; then
  echo "success"
else
  echo "error: failed to update qBittorrent port"
  exit 1
fi
