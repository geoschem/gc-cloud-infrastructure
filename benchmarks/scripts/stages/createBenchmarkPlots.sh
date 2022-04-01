#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "CreateBenchmarkPlots"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"      # working directory
: "${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}"  # primary key of ref in the database
: "${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"  # primary key of dev in the database

run_stage_name="RunGCHP"

function download_latest_gcpy() {
    git clone https://github.com/geoschem/gcpy.git --branch dev --depth 1
    export PYTHONPATH=$(pwd)/gcpy
}

# Download GCPy
download_latest_gcpy

# Download ref and dev output
mkdir ref
(
    cd ref
    download_artifacts "${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}"
)
mkdir dev
(
    cd dev
    download_artifacts "${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"
)

# Create weights dir
mkdir weights


# Create GCPy configuration file (and fill it in)
envsubst < $GEOSCHEM_BENCHMARK_PLOTTING_CONFIG_FILE > benchmark.yml
python gcpy/benchmark/run_benchmark.py benchmark.yml

# Upload the PDF files
mv dev/run-directory/BenchmarkResults/GCHP_version_comparison GCHP_version_comparison
upload_public_artifacts GCHP_version_comparison/**/*.pdf
