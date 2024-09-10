#!/bin/sh

# This script is a workaround for podman-compose absence of support for depends_on

DYNAMIC_PLUGINS_CONFIG="dynamic-plugins-root/app-config.dynamic-plugins.yaml"


while [ ! -f "$DYNAMIC_PLUGINS_CONFIG" ]; do
    echo "Waiting for $DYNAMIC_PLUGINS_CONFIG to be created by install-dynamic-plugins container ..."
    sleep 2 
done


node packages/backend --no-node-snapshot \
    --config app-config.yaml \
    --config app-config.example.yaml \
    --config app-config.example.production.yaml \
    --config app-config.local.yaml \
    --config $DYNAMIC_PLUGINS_CONFIG