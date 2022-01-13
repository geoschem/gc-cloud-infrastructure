#!/usr/bin/env bash

temp_dir=$(mktemp --directory)
export GEOSCHEM_BENCHMARK_WORKING_DIR=${GEOSCHEM_BENCHMARK_WORKING_DIR:=${temp_dir}}    # working directory for this stage
export GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR=$(mktemp --directory)                     # directory whose contents are saved as artifacts
log_file=$(mktemp)

set -e  # exit on any error
set -u  # treat undefined variables as an error

: "${GEOSCHEM_BENCHMARK_S3_BUCKET}" "${GEOSCHEM_BENCHMARK_INSTANCE_ID}"

stage_script=$(realpath $1)  # script that will be executed
stage_short_name=$2          # name of this stage (one word)

s3_artifacts_dir=${GEOSCHEM_BENCHMARK_S3_BUCKET}/${GEOSCHEM_BENCHMARK_INSTANCE_ID}      # s3 path to artifact files
stage_artifact_filename=${GEOSCHEM_BENCHMARK_INSTANCE_ID}-${stage_short_name}.tar.gz    # file name of this stage's artifact file

function stage_has_already_run() {
    aws s3 ls ${s3_artifacts_dir}/${stage_artifact_filename} &> /dev/null
}

function download_artifacts() {
    if aws s3 ls ${s3_artifacts_dir} &> /dev/null ; then
        aws s3 cp ${s3_artifacts_dir}/ . --recursive --exclude "*" --include "${GEOSCHEM_BENCHMARK_INSTANCE_ID}-*.tar.gz"
        for artifact_file in *.tar.gz; do
            tar -xvzf ${artifact_file}
        done
    fi
}

function upload_artifacts() {
    tar -cvzf ${stage_artifact_filename} --directory=${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR} .
    aws s3 cp ${stage_artifact_filename} ${s3_artifacts_dir}/${stage_artifact_filename}
    rm -f ${stage_artifact_filename}
}

function upload_log_file() {
    aws s3 cp ${log_file} ${s3_artifacts_dir}/logs/${stage_short_name}.txt
}

if ! stage_has_already_run; then
    echo "Running stage '${stage_short_name}'"

    # subshell so we return to cwd afterwards
    (
        set -x  # print commands to log file
        cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
        download_artifacts
        
        set -o pipefail        
        ${stage_script} 2>&1 | tee ${log_file} && upload_artifacts
        set +o pipefail
    )

    upload_log_file
else 
    echo "Stage '${stage_short_name}' is already complete"
fi
rm -rf ${temp_dir} ${GEOSCHEM_BENCHMARK_STAGE_ARTIFACTS_DIR} ${log_file}
