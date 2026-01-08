#!/bin/bash

if [[ ! -f build-config ]]; then
  echo "Missing build configuration"
  exit 1
fi

. build-config

CORES="${CORES:-$(nproc)}"

dockerBuild() {
  local target="$1"
  local tag="$2"
  local tag_attrib

  if [[ -n "${tag}" ]]; then
    tag_attrib="--tag ${tag}"
  fi

  # shellcheck disable=SC2086
  docker build --progress=plain -f Dockerfile \
    --build-arg MODEL="${MODEL}" \
    --build-arg BIT_WIDTH="${BIT_WIDTH}" \
    --build-arg GIT_REF="${GIT_REF}" \
    --build-arg VERSION="${VERSION}" \
    --build-arg CORES="${CORES}" \
    --target "${target}" \
    ${tag_attrib} \
    context
}

#dockerBuild source rpi-kernel-src
dockerBuild final rpi-chaoskey
