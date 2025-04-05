#!/bin/bash

# Detect the default gateway dynamically
GATEWAY=$(/sbin/ip route | grep default | awk '{print $3}')

# Check if route already exists
if /sbin/ip route | grep -q "10.10.10.0/24"; then
  echo "LAN route already exists. Skipping."
else
  /sbin/ip route add 10.10.10.0/24 via ${GATEWAY}
  echo "Added LAN route via ${GATEWAY}"
fi
