#!/bin/bash

export GEOSCHEM_BENCHMARK_INSTANCE_ID=1234-testingUtils
export GEOSCHEM_BENCHMARK_S3_BUCKET=s3://washu-benchmarks-cloud
export GEOSCHEM_BENCHMARK_TABLE_NAME=geoschem_testing
export GEOSCHEM_BENCHMARK_SITE=WUSTL

./helpers/dbCreateTest.sh

set -e
./testing/stage1.sh
./testing/stage2.sh
./testing/stage3.sh
