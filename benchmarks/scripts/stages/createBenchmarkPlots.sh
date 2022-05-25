#!/usr/bin/env bash

. ${GEOSCHEM_BENCHMARK_SCRIPTS}/helpers/runStage.sh "CreateBenchmarkPlots"

set -e
set -u
set -x

: "${GEOSCHEM_BENCHMARK_WORKING_DIR}"      # working directory
: "${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}"  # primary key of ref in the database
: "${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"  # primary key of dev in the database

run_stage_name="Plotting"

# update the plotting config file to use correct settings
function update_plotting_config_file() {
    filename=$1
    results_dir="dev-gchp"
    case ${GEOSCHEM_BENCHMARK_COMPARISON_TYPE} in
        gcc_gcc)
            sed -i '/gcc_vs_gcc:/{n;s/run: False/run: True/;}' $filename
            results_dir="dev-gcc"
            ;;
        gchp_gchp)
            sed -i '/gchp_vs_gchp:/{n;s/run: False/run: True/;}' $filename
            ;;
        gchp_gcc)
            sed -i '/gchp_vs_gcc:/{n;s/run: False/run: True/;}' $filename
            ;;
        gcc_gchp)
            sed -i '/gchp_vs_gcc:/{n;s/run: False/run: True/;}' $filename
            ;;
        diff_of_diffs)
            sed -i '/gchp_vs_gcc_diff_of_diffs:/{n;s/run: False/run: True/;}' $filename
            diff_refdir="ref-${GEOSCHEM_BENCHMARK_DIFF_TYPE}"
            diff_devdir="dev-${GEOSCHEM_BENCHMARK_DIFF_TYPE}"

            # download additional diff dirs
            mkdir $diff_devdir
            (
                cd $diff_devdir
                download_artifacts "${GEOSCHEM_BENCHMARK_DIFF_DEV_PRIMARY_KEY}"
            )
            mkdir $diff_refdir
            (
                cd $diff_refdir
                download_artifacts "${GEOSCHEM_BENCHMARK_DIFF_REF_PRIMARY_KEY}"
            )
            ;;
        *)
            >&2 echo "error: unknown comparison type '${GEOSCHEM_BENCHMARK_COMPARISON_TYPE}' (GEOSCHEM_BENCHMARK_COMPARISON_TYPE)"
            exit 1
            ;;
    esac
}

function download_latest_gcpy() {
    git clone https://github.com/geoschem/gcpy.git --branch dev --depth 1
    export PYTHONPATH=$(pwd)/gcpy
}

# Download GCPy
download_latest_gcpy

# Select directory names for ref and dev
devdir="dev-${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}"
if [[ "x${GEOSCHEM_BENCHMARK_REF_MODEL_TYPE}" == "x${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}" ]]; then 
    refdir="ref-${GEOSCHEM_BENCHMARK_REF_MODEL_TYPE}"
else
    refdir="dev-${GEOSCHEM_BENCHMARK_REF_MODEL_TYPE}"
fi

# Download ref and dev output
mkdir $refdir
(
    cd $refdir
    download_artifacts "${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}"
)
mkdir $devdir
(
    cd $devdir
    download_artifacts "${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"
)

# Create weights dir
mkdir weights

# Create GCPy configuration file (and fill it in)
envsubst < $GEOSCHEM_BENCHMARK_PLOTTING_CONFIG_FILE > benchmark.yml
update_plotting_config_file benchmark.yml
python gcpy/benchmark/run_benchmark.py benchmark.yml

# Upload the PDF files
mv "${results_dir}/run-directory/BenchmarkResults" BenchmarkResults
files=`find BenchmarkResults -type f`
upload_public_artifacts $files
