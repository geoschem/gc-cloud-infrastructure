#!/usr/bin/env bash

. ./helpers/runStage.sh

set -e
set -u
set -x

echo "This is stage1"

echo "artifact1" > artifact1.txt
upload_artifacts art1 artifact1.txt
