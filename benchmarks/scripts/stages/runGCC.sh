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
        /usr/bin/time -v ./gcclassic
        ;;
    AWS)
        /usr/bin/time -v ./gcclassic 2>&1 | tee runlog.txt
        # Add peak memory and wall time to stage metadata
        memory=$(sed -n 's#Maximum resident set size (kbytes):  *\([0-9][0-9]*\)#\1#p' runlog.txt | sed 's#\t##')
        wallTime=$(sed -n 's#Elapsed (wall clock) time (h:mm:ss or m:ss):  *\([0-9].*\)#\1#p' runlog.txt | sed 's#\t##')
        echo "{\"PeakMemory\":  \"${memory} KB\", \"WallTime\":  \"${wallTime} KB\"}" > metadata.json
        mv HEMCO.log OutputDir/HEMCO.log
        ;;
    *)
        >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
        exit 1
        ;;
esac

cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
upload_artifacts OutputDir run-directory/OutputDir/* run-directory/species_database.yml run-directory/GEOSChem.Restart.*
