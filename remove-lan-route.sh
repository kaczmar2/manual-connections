#!/bin/bash

# Remove the specific LAN route
/sbin/ip route del 10.10.10.0/24
echo "Removed LAN route"
