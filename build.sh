#!/bin/bash

source .env
export DOCKER_BUILDKIT=1
docker-compose build \
  --build-arg PRODUCT_EDITION=$PRODUCT_EDITION \
  --build-arg RELEASE_VERSION=$RELEASE_VERSION
