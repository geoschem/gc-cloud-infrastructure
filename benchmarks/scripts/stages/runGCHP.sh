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

# get number of processes and start date
GC_VERSION=$(echo ${GEOSCHEM_BENCHMARK_INSTANCE_ID} | sed "s#^[^-]*-[^-]*-[^-]*-##" | sed "s#[.].*##")
if [[ "x${GC_VERSION}" == "x13" ]]; then
    num_proc=$(sed -n 's#TOTAL_CORES=\([0-9][0-9]*\)#\1#p' runConfig.sh)
else 
    num_proc=$(sed -n 's#TOTAL_CORES=\([0-9][0-9]*\)#\1#p' setCommonRunSettings.sh)
    start_str=$(sed 's/ /_/g' cap_restart)
fi

# launch GCHP
case ${GEOSCHEM_BENCHMARK_SITE} in
    WUSTL)
        export TMPDIR="$__LSF_JOB_TMPDIR__"
        wustl_extdata_setup_hook
        chmod +x ./gchp
        mpiexec -n ${num_proc} ./gchp
        ;;
    AWS)
        /usr/bin/time -v mpiexec -n ${num_proc} ./gchp 2>&1 | tee runlog.txt
        # Add peak memory and wall time to stage metadata
        memory=$(sed -n 's#Maximum resident set size (kbytes):  *\([0-9][0-9]*\)#\1#p' runlog.txt | sed 's#\t##')
        wallTime=$(sed -n 's#Elapsed (wall clock) time (h:mm:ss or m:ss):  *\([0-9].*\)#\1#p' runlog.txt | sed 's#\t##')
        echo "{\"PeakMemory\":  \"${memory} KB\", \"WallTime\":  \"${wallTime} KB\"}" > metadata.json
        ;;
    *)
        >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
        exit 1
        ;;
esac

# rename restart to conform to gcpy compliant format
if [[ "x${GC_VERSION}" == "x13" ]]; then
    mv gcchem_internal_checkpoint "gcchem_internal_checkpoint.restart.${GEOSCHEM_BENCHMARK_END_DATE}_${GEOSCHEM_BENCHMARK_DURATION_HOURS}.nc4"
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    upload_artifacts OutputDir run-directory/OutputDir/* run-directory/gcchem_internal_checkpoint* run-directory/species_database.yml
else
    new_start_str=$(sed 's/ /_/g' cap_restart)
    if [[ "${new_start_str}" = "${start_str}" || "${new_start_str}" = "" ]]; then
    echo "ERROR: cap_restart either did not change or is empty."
    exit 1
    else
        N=$(grep "CS_RES=" setCommonRunSettings.sh | cut -c 8- | xargs )    
        mv gcchem_internal_checkpoint Restarts/GEOSChem.Restart.${new_start_str:0:13}z.c${GEOSCHEM_BENCHMARK_RESOLUTION}.nc4
        source setRestartLink.sh
    fi
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    upload_artifacts OutputDir run-directory/OutputDir/* run-directory/Restarts/* run-directory/species_database.yml
fi


