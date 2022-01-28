#!/bin/bash
#BSUB -n 2
#BSUB -R 'rusage[mem=4GB] span[ptile=2]'
#BSUB -q rvmartin
#BSUB -a 'docker(public.ecr.aws/geoschem-wustl/geoschem_benchmark:latest)'
#BSUB -g /liam.bindle/gcst-benchmarks
#BSUB -Ne
#BSUB -o 1234-testingUtils.txt

.  /etc/bashrc

export GEOSCHEM_BENCHMARK_INSTANCE_ID=1234-testingUtils
export GEOSCHEM_BENCHMARK_S3_BUCKET=s3://washu-benchmarks-cloud
export GEOSCHEM_BENCHMARK_TABLE_NAME=geoschem_testing
export GEOSCHEM_BENCHMARK_SITE=WUSTL

./helpers/dbCreateTest.sh

set -e
./testing/stage1.sh
./testing/stage2.sh
./testing/stage3.sh

