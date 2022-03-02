#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "RunGCHP"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"  # working directory
: "${GEOSCHEM_BENCHMARK_SITE}"         # which site is this running at

cd run-directory

# get number of processes
num_proc=$(sed -n 's#TOTAL_CORES=\([0-9][0-9]*\)#\1#p' runConfig.sh)

# launch GCHP
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        export TMPDIR="$__LSF_JOB_TMPDIR__"
        chmod +x ./gchp
        mpiexec -n ${num_proc} ./gchp
        ;;
    AWS)
        mpiexec -n ${num_proc} ./gchp
        ;;
    *)
        >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
        exit 1
        ;;
esac

cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
upload_artifacts OutputDir run-directory/OutputDir/* run-directory/gcchem_internal_checkpoint*
