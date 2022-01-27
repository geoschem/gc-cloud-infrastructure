#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "CreateBenchmarkPlots"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"  # working directory
: "${GEOSCHEM_BENCHMARK_REFPK}"        # primary key of ref in the database
: "${GEOSCHEM_BENCHMARK_DEVPK}"        # primary key of dev in the database

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
    download_artifacts "${GEOSCHEM_BENCHMARK_REFPK}"
)
mkdir dev
(
    cd dev
    download_artifacts "${GEOSCHEM_BENCHMARK_DEVPK}"
)

# Create weights dir
mkdir weights


# Create GCPy configuration file (and fill it in)
envsubst < ${GEOSCHEM_BENCHMARK_SCRIPTS}/stages/resources/template.1mo_benchmark.yml > 1mo_benchmark.yml
python gcpy/benchmark/run_1mo_benchmark.py 1mo_benchmark.yml

# Upload the PDF files
upload_public_artifacts dev/run-directory/BenchmarkResults/GCHP_version_comparison/**/*.pdf
