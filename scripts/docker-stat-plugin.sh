#!/usr/bin/env bash
CTR="${DISCOURSE_DEV_CONTAINER:-discourse_dev}"
docker exec -u discourse "$CTR" node -e \
  'require("fs").statSync("/src/plugins/rt-lucky-spin/assets/javascripts"); console.log("stat ok")'
