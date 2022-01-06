#!/usr/bin/env bash

# Description: Clone and checkout the corresponding git tag or commit hash given
# by the env variable TAG_NAME into the specified directory. If no, tag name present,
# exit with code 1.
#
# Usage:
#   ./get-repo.sh <simulation-type> <directory-path>
#       simulation-type: either GCC or GCHP. Determines which git repo to clone
#       directory-path: path to clone the repo to (eg. /gc-src
trap 'echo "Error in get-repo.sh"; exit 1' ERR

if [[ "x$1" == "xGCHP" ]]; then
  REPO="https://github.com/geoschem/GCHP.git"
elif [[ "x$1" == "xGCC" ]]; then
  REPO="https://github.com/geoschem/GCClassic.git"
else
  echo "ERROR: Invalid parameter for simulation type given: $1"
  exit 1
fi

if [[ -z "$2" ]]; then
  echo "ERROR: No parameter for directory-path given"
  exit 1
fi

# if supplied checkout the relevant tag
if [[ ! -z "${TAG_NAME}" ]]; then
  cd /
  echo "Cloning $1 and checking out ${TAG_NAME}"
  git clone ${REPO} /gc-src
  cd /gc-src
  git checkout ${TAG_NAME}
  git submodule update --init --recursive
else
  echo "ERROR: No TAG_NAME environment variable specified"
  exit 1
fi
