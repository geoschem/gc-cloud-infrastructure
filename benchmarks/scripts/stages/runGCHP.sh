#!/usr/bin/env bash

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}"  # directory for stage artifacts
: "${GEOSCHEM_BENCHMARK_SITE}"                 # which site is this running at


cd run-directory

# get number of processes
num_proc=$(sed -n 's#TOTAL_CORES=\([0-9][0-9]*\)#\1#p' runConfig.sh)

# launch GCHP
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        mpiexec -n ${num_proc} ./gchp
        ;;
    AWS)
        mpirun --allow-run-as-root --hostfile hostfile.txt -np ${num_proc} ./gchp
        ;;
    *)
        >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
        exit 1
        ;;
esac

# move OutputDir to artifacts directory
mkdir -p ${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}/run-directory
mv OutputDir ${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}/run-directory
