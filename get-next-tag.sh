#!/bin/bash
TARGET_REPO="$1"

if [ -z "$TARGET_REPO" ]; then
    echo "1.0.1"
    exit 0
fi

# Consultar las etiquetas existentes en Docker Hub
TAGS_JSON=$(curl -s "https://hub.docker.com/v2/repositories/${TARGET_REPO}/tags?page_size=100")

# Extraer el número más alto que coincida con el patrón 1.0.X
MAX_PATCH=$(echo "$TAGS_JSON" | grep -o '"name":"1\.0\.[0-9]*"' | sed 's/.*1\.0\.//;s/"//' | sort -n | tail -1)

if [ -z "$MAX_PATCH" ]; then
    NEXT_PATCH=1
else
    NEXT_PATCH=$((MAX_PATCH + 1))
fi

echo "1.0.${NEXT_PATCH}"
