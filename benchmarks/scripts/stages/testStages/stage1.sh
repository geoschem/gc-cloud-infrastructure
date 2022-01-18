#!/usr/bin/env bash

set -e
set -u
set -x

echo "This is stage1"

echo "artifact1" > artifact1.txt
upload_artifacts artifact1.txt
