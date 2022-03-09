#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "RunGCC"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"  # working directory
: "${GEOSCHEM_BENCHMARK_SITE}"         # which site is this running at

cd run-directory

# launch GCC
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        export TMPDIR="$__LSF_JOB_TMPDIR__"
        chmod +x ./gcclassic
        ./gcclassic
        ;;
    AWS)
        ./gcclassic
        mv HEMCO.log OutputDir/HEMCO.log
        mv GEOSChem.Restart.* OutputDir/
        ;;
    *)
        >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
        exit 1
        ;;
esac

cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
upload_artifacts OutputDir run-directory/OutputDir/*
