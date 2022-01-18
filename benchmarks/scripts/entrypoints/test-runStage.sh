#!/bin/bash

set -u
: "${GEOSCHEM_BENCHMARK_INSTANCE_ID}"

export GEOSCHEM_BENCHMARK_TABLE_NAME=geoschem_testing

#export GEOSCHEM_BENCHMARK_INSTANCE_ID=1234-testStages
export GEOSCHEM_BENCHMARK_S3_BUCKET=s3://washu-benchmarks-cloud
export GEOSCHEM_BENCHMARK_SITE=WUSTL

pwd

./helpers/runStage.sh ./stages/testStages/stage1.sh "Stage1"
./helpers/runStage.sh ./stages/testStages/stage2.sh "Stage2"
./helpers/runStage.sh ./stages/testStages/stage3.sh "Stage3"
