#!/usr/bin/env bash

export TMPDIR=${GEOSCHEM_BENCHMARK_TEMPDIR_PREFIX:-${TMPDIR}}  # prefix of temporary directories (if specified)

temp_dir=$(mktemp --directory)
export GEOSCHEM_BENCHMARK_WORKING_DIR=${GEOSCHEM_BENCHMARK_WORKING_DIR:=${temp_dir}}    # working directory for this stage
log_file=$(mktemp)

set -e  # exit on any error
set -u  # treat undefined variables as an error
set -x

: "${GEOSCHEM_BENCHMARK_S3_BUCKET}" "${GEOSCHEM_BENCHMARK_INSTANCE_ID}" "${GEOSCHEM_BENCHMARK_TABLE_NAME}"

stage_script=$(realpath $1)  # script that will be executed
stage_short_name=$2          # name of this stage (one word)

s3_artifacts_dir=${GEOSCHEM_BENCHMARK_S3_BUCKET}/${GEOSCHEM_BENCHMARK_INSTANCE_ID}/Artifacts    # s3 path to artifact files
s3_logs_dir=${GEOSCHEM_BENCHMARK_S3_BUCKET}/${GEOSCHEM_BENCHMARK_INSTANCE_ID}/Logs

function stage_has_already_run() {
    aws dynamodb get-item \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
        --attributes-to-get "StagesCompleted" | jq -e ".Item.StagesCompleted.L[] | select(.S == \"${stage_short_name}\")" &> /dev/null
}

function download_artifacts() {
    if aws s3 ls ${s3_artifacts_dir} &> /dev/null ; then
        aws s3 cp ${s3_artifacts_dir}/ . --recursive --only-show-errors
    fi
}

function upload_artifacts() {
    for file_path in "$@"; do
        aws s3 cp ${file_path} ${s3_artifacts_dir}/${file_path} --only-show-errors
    done
}
export -f upload_artifacts


function register_stage_completed() {
    aws dynamodb update-item \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
        --update-expression "SET #s = list_append(#s, :vals)" \
        --expression-attribute-names '{"#s": "StagesCompleted"}' \
        --expression-attribute-values "{\":vals\": {\"L\": [ { \"S\": "${s3_log_file_name}" }]}}"
}

function exec_stage() {
    (
        set -x  # print commands to log file
        cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
        download_artifacts
        
        set -o pipefail        
        ${stage_script} 2>&1 | tee ${log_file}
        set +o pipefail
    )
}

function upload_log_file() {
    s3_log_file_name=${s3_logs_dir}/${stage_short_name}.txt
    aws s3 cp ${log_file} ${s3_log_file_name} --only-show-errors
    aws dynamodb update-item \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
        --update-expression "SET #s = list_append(#s, :vals)" \
        --expression-attribute-names '{"#s": "LogFiles"}' \
        --expression-attribute-values "{\":vals\": {\"L\": [ { \"S\": "${s3_log_file_name}" }]}}"
}

if ! stage_has_already_run; then
    echo "Running stage '${stage_short_name}'"

    if exec_stage ; then
        register_stage_completed
        upload_log_file
    else
        upload_log_file
        exit 1
    fi
else 
    echo "Stage '${stage_short_name}' is already complete"
fi
rm -rf ${temp_dir} ${log_file}
