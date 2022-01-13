#!/usr/bin/env bash

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}"  # directory for stage artifacts
: "${GEOSCHEM_BENCHMARK_SITE}"                 # which site is this running at

cd run-directory
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        mpirun -np 72 ./gchp
        ;;
    AWS)
        mpirun --allow-run-as-root --hostfile hostfile.txt -np 72 ./gchp
        ;;
    *)
        >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
        exit 1
        ;;
esac

# move OutputDir to artifacts directory
mkdir -p ${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}/run-directory
mv OutputDir ${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR}/run-directory
