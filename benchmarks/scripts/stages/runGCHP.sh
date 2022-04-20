#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "RunGCHP"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"  # working directory
: "${GEOSCHEM_BENCHMARK_SITE}"         # which site is this running at

cd run-directory

function wustl_extdata_setup_hook() {
    # if EXTDATA_DIR is a subdirectory of the tempdir, sync using bashdatacatalog
    case ${GEOSCHEM_BENCHMARK_EXTDATA_DIR} in
        ${GEOSCHEM_BENCHMARK_TEMPDIR_PREFIX}*)
            echo "Making a fresh copy of ExtData for this test at '${GEOSCHEM_BENCHMARK_EXTDATA_DIR}'"
            (
                mkdir -p ${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
                cd ${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
                cp /storage1/fs1/rvmartin/Active/GEOS-Chem-shared/ExtData/DataCatalogs/${GEOSCHEM_BENCHMARK_CATALOGS_FOR_VERSION}/*.csv .
                cp /storage1/fs1/rvmartin/Active/GEOS-Chem-shared/ExtData/DataCatalogs/MeteorologicalInputs.csv .
                bashdatacatalog-fetch *.csv
                bashdatacatalog-list -am -r 2019-06-31,2019-07-02 -f rsync *.csv > transfer_list.txt
                rsync -avip --files-from=transfer_list.txt /storage1/fs1/rvmartin/Active/GEOS-Chem-shared/ExtData .
            )
            ;;
    esac
}

# get number of processes
num_proc=$(sed -n 's#TOTAL_CORES=\([0-9][0-9]*\)#\1#p' runConfig.sh)

# launch GCHP
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        export TMPDIR="$__LSF_JOB_TMPDIR__"
        wustl_extdata_setup_hook
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
