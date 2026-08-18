#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-0.1.0-beta.1}"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"

if [[ ! -f "$ROOT/PIAlert/PIAlert.toc" ]]; then
  echo "Missing PIAlert.toc" >&2
  exit 1
fi

( cd "$ROOT" && zip -q -r "$DIST/PIAlert-${VERSION}.zip" PIAlert )
unzip -Z1 "$DIST/PIAlert-${VERSION}.zip"
