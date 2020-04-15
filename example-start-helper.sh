#!/usr/bin/env bash
set -e
export NODE_CONFIG='{
      "server": {
        "siteUrl": "'${DS_URL:-"/"}'"
      }
    }'

exec "$@"