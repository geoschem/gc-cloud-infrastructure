#!/usr/bin/env bash

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}"  # directory for stage artifacts
: "${GEOSCHEM_BENCHMARK_COMMIT_ID}"            # commit ID to use
: "${GEOSCHEM_BENCHMARK_EXTDATA_DIR}"          # path to ExtData

function download_code() {
    git clone https://github.com/geoschem/GCHP.git .
    git checkout ${GEOSCHEM_BENCHMARK_COMMIT_ID}
    git submodule update --init --recursive
}


function create_run_directory() {
    cd run
    ./createRunDir.sh << EOF
${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
1
2
1
${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}
run-directory
n
EOF
    cd ..
}

function install_geoschem_to_run_directory() {
    mkdir build
    cd build
    cmake .. -DRUNDIR=${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}/run-directory
    make -j4 install
    cd ..
}

download_code
create_run_directory
install_geoschem_to_run_directory
