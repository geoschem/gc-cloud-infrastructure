#!/usr/bin/env bash

set -e
set -u
set -x

echo "This is stage2"

[ -f artifact1.txt ] || exit 1

mkdir foo1
echo "artifact2" > foo1/artifact2.txt
echo "artifact3" > foo1/artifact3.txt
upload_artifacts foo1/*
