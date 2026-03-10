#!/usr/bin/env bash
# Generic JSON Schema validator wrapping ajv-cli.
#
# Implements the Terraform external data source protocol:
#   stdin  → { "schema_file": "<path>", "data_file": "<path>" }
#   stdout → { "valid": "true", "count": "<n>" }
#   exit 1 + stderr on failure
#
# Standalone usage (no stdin):
#   bash validate.sh <schema_file> <data_file>

set -euo pipefail

if [[ $# -ge 2 ]]; then
  # Standalone: bash validate.sh <schema_file> <data_file>
  schema_file="$1"
  data_file="$2"
else
  # Terraform external data source: query arrives on stdin as JSON
  query=$(cat)
  schema_file=$(echo "$query" | jq -r '.schema_file')
  data_file=$(echo "$query"   | jq -r '.data_file')
fi

if output=$(npx ajv-cli@5 validate -s "$schema_file" -d "$data_file" --spec=draft2020 2>&1); then
  count=$(jq 'length' "$data_file")
  echo "{\"valid\":\"true\",\"count\":\"${count}\"}"
else
  echo "$output" >&2
  exit 1
fi
