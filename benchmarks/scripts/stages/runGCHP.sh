#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "RunGCHP"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"  # working directory
: "${GEOSCHEM_BENCHMARK_SITE}"         # which site is this running at


function wustl_create_temporary_extdata() {
    (
        mkdir -p ${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
        cd ${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
        bashdatacatalog ${GEOSCHEM_BENCHMARK_CATALOG_FILES} fetch
        bashdatacatalog ${GEOSCHEM_BENCHMARK_CATALOG_FILES} list-missing relative 2019-06-30 2019-07-02 > temp-extdata-files.txt
        rsync -avip --link-dest=/storage1/fs1/rvmartin/Active/GEOS-Chem-shared/ExtData/ --files-from=temp-extdata-files.txt /storage1/fs1/rvmartin/Active/GEOS-Chem-shared/ExtData/ ./
    )
}

cd run-directory

# get number of processes
num_proc=$(sed -n 's#TOTAL_CORES=\([0-9][0-9]*\)#\1#p' runConfig.sh)

# launch GCHP
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        #[ ! -z "${GEOSCHEM_BENCHMARK_CATALOG_FILES}" ] && wustl_create_temporary_extdata
        export TMPDIR="$__LSF_JOB_TMPDIR__"
        chmod +x ./gchp
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

cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
upload_artifacts OutputDir run-directory/OutputDir/* run-directory/gcchem_internal_checkpoint*
