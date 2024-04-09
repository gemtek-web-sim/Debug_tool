#!/bin/sh

QUERY_STRING="enpwd=GemtekUser&time=20240411_110530&info=version_and_hardware_info+backup_config+iptables_func"

# Extract arguments from the query string
enpwd=$(echo "$QUERY_STRING" | sed -n 's/^.*enpwd=\([^&]*\).*$/\1/p')
time=$(echo "$QUERY_STRING" | sed -n 's/^.*time=\([^&]*\).*$/\1/p')
info=$(echo "$QUERY_STRING" | sed -n 's/^.*info=\([^&]*\).*$/\1/p')

echo "Argument 1: $enpwd"
echo "Argument 2: $time"
echo "Argument 3: $info"
