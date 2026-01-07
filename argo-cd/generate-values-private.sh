#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 /path/to/private-key.pem [output-file (or default: values-private.yaml)]" >&2
  exit 2
fi

PEM_FILE="$1"
OUT_FILE="${2:-values-private.yaml}"

if [ ! -f "$PEM_FILE" ]; then
  echo "PEM file not found: $PEM_FILE" >&2
  exit 3
fi

# YAML indentation: key lines at 8 spaces, block content indented 10 spaces
INDENT="          "

# mkdir -p "$(dirname "$OUT_FILE")"

cat >"$OUT_FILE" <<EOF
parent-argo-cd:
  configs:
    credentialTemplates:
      github-repos:
        githubAppPrivateKey: |
EOF
sed "s/^/${INDENT}/" "$PEM_FILE" >>"$OUT_FILE"

cat >>"$OUT_FILE" <<EOF

      ghcr-oci:
        githubAppPrivateKey: |
EOF
sed "s/^/${INDENT}/" "$PEM_FILE" >>"$OUT_FILE"

echo "Generated $OUT_FILE"
