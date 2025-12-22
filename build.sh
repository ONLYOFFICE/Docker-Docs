#!/bin/bash

source .env
export DOCKER_BUILDKIT=1
docker-compose -f build.yml build \
  --build-arg DOCKERFILE=$DOCKERFILE \
  --build-arg PRODUCT_EDITION=$PRODUCT_EDITION \
  --build-arg RELEASE_VERSION=$RELEASE_VERSION \
  --build-arg DS_VERSION_HASH=$(echo -n "$(date +'%Y.%m.%d-%H%M')" | md5sum | awk '{print $1}')
