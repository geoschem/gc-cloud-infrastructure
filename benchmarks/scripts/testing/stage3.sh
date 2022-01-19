#!/usr/bin/env bash

. ./helpers/runStage.sh "Stage3"

set -e
set -u
set -x

echo "This is stage3"

[ -f artifact1.txt ] || exit 1
[ -f foo1/artifact3.txt ] || exit 1
[ -f foo1/artifact2.txt ] || exit 1

echo "all the files are present"
