#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "SetupRunDirectory"

set -e
set -u
set -x


: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"          # working directory
: "${GEOSCHEM_BENCHMARK_COMMIT_ID}"            # commit ID to use
: "${GEOSCHEM_BENCHMARK_EXTDATA_DIR}"          # path to ExtData
: "${GEOSCHEM_BENCHMARK_SITE}"                 # site running at

# load modules for specified model
case ${GEOSCHEM_BENCHMARK_MODEL} in
    gcc)
        source ${GEOSCHEM_BENCHMARK_SCRIPTS}/stages/modules/gcc-modules.sh
        ;;
    gchp)
        source ${GEOSCHEM_BENCHMARK_SCRIPTS}/stages/modules/gchp-modules.sh
        ;;
    *)
        >&2 echo "error: invalid model type: ${GEOSCHEM_BENCHMARK_MODEL}. Use gchp or gcc."
        exit 1
        ;;
esac

download_code
create_run_directory
configure_run_directory
install_geoschem_to_run_directory

cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
upload_artifacts RunDirectory run-directory/*
