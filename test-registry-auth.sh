#!/bin/bash
# Test: Registry Auth File Detection for Private OCI Registries
# This script demonstrates two scenarios:
#   1. No REGISTRY_AUTH_FILE_PATH set (placeholder mounted) → auth skipped
#   2. REGISTRY_AUTH_FILE_PATH set to host auth file → auth detected and set

cd "$(dirname "$0")"

# Ensure podman socket is discoverable
PODMAN_SOCK=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || true)
if [ -n "$PODMAN_SOCK" ] && [ -z "$DOCKER_HOST" ]; then
    export DOCKER_HOST="unix://$PODMAN_SOCK"
fi

echo "=============================================="
echo "  Registry Auth File Detection Test"
echo "=============================================="
echo ""

# --- Scenario 1: No auth file path set ---
echo ">>> Scenario 1: REGISTRY_AUTH_FILE_PATH is NOT set"
echo ">>> Expected: 'No registry auth file mounted, skipping REGISTRY_AUTH_FILE'"
echo ""

# Ensure REGISTRY_AUTH_FILE_PATH is commented out
sed -i.bak 's/^REGISTRY_AUTH_FILE_PATH=/#REGISTRY_AUTH_FILE_PATH=/' .env 2>/dev/null || true

podman compose run --rm install-dynamic-plugins

echo ""
echo "----------------------------------------------"
echo ""

# --- Scenario 2: Auth file path set ---
echo ">>> Scenario 2: REGISTRY_AUTH_FILE_PATH=~/.config/containers/auth.json"
echo ">>> Expected: 'Found registry auth file, setting REGISTRY_AUTH_FILE'"
echo ""

# Set REGISTRY_AUTH_FILE_PATH
sed -i.bak 's|^#REGISTRY_AUTH_FILE_PATH=.*|REGISTRY_AUTH_FILE_PATH=~/.config/containers/auth.json|' .env

podman compose run --rm install-dynamic-plugins

echo ""
echo "=============================================="
echo "  Both scenarios completed!"
echo "=============================================="

# Cleanup: restore .env
sed -i.bak 's|^REGISTRY_AUTH_FILE_PATH=.*|#REGISTRY_AUTH_FILE_PATH=|' .env
rm -f .env.bak
