#!/bin/bash
# Launches the NGIAB Data Visualizer. The real script lives in CIROH-UA/ngiab-client;
# this fetches a pinned version of it so there is a single source of truth.
set -euo pipefail

VISUALIZER_REF="${VISUALIZER_REF:-v1.2.0}"
VISUALIZER_SHA256="${VISUALIZER_SHA256:-c4aa5ebbff4a2ab3093044758add64dd221ffe7d244dce3b8ce949e0d3644a28}"
URL="https://raw.githubusercontent.com/CIROH-UA/ngiab-client/${VISUALIZER_REF}/viewOnTethys.sh"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ngiab"
SCRIPT="$CACHE_DIR/viewOnTethys-${VISUALIZER_REF//\//_}.sh"

mkdir -p "$CACHE_DIR"
if [ ! -s "$SCRIPT" ]; then
    echo "Fetching visualizer launcher ${VISUALIZER_REF}..."
    curl -fsSL "$URL" -o "$SCRIPT.tmp" || { echo "Could not download $URL" >&2; exit 1; }
    mv "$SCRIPT.tmp" "$SCRIPT"
fi

if [ "$VISUALIZER_SHA256" != "skip" ]; then
    echo "${VISUALIZER_SHA256}  ${SCRIPT}" | sha256sum -c --quiet - || {
        echo "Checksum mismatch for $SCRIPT; refusing to run it." >&2
        rm -f "$SCRIPT"; exit 1
    }
fi

exec bash "$SCRIPT" "$@"
