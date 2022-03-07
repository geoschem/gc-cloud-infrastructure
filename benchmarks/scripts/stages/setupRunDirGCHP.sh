#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "SetupRunDirectory"

set -e
set -u
set -x

# import gchp specific functions
source ${GEOSCHEM_BENCHMARK_SCRIPTS}/stages/modules/gchp-modules.sh

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"          # working directory
: "${GEOSCHEM_BENCHMARK_COMMIT_ID}"            # commit ID to use
: "${GEOSCHEM_BENCHMARK_EXTDATA_DIR}"          # path to ExtData
: "${GEOSCHEM_BENCHMARK_SITE}"                 # site running at


download_code
create_run_directory
configure_run_directory
install_geoschem_to_run_directory

cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
upload_artifacts RunDirectory run-directory/*
