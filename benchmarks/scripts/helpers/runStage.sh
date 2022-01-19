#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    >&2 echo "error: no stage name was given"
    exit 1
fi

export TMPDIR=${GEOSCHEM_BENCHMARK_TEMPDIR_PREFIX:-${TMPDIR}}  # prefix of temporary directories (if specified)
temp_dir=$(mktemp --directory)
export GEOSCHEM_BENCHMARK_WORKING_DIR=${GEOSCHEM_BENCHMARK_WORKING_DIR:=${temp_dir}}    # working directory for this stage

set -e  
set -u

# required variables
: "${GEOSCHEM_BENCHMARK_S3_BUCKET}"     # S3 bucket URI (for artifact upload)
: "${GEOSCHEM_BENCHMARK_INSTANCE_ID}"   # Unique ID of test (commit_id + test_code)
: "${GEOSCHEM_BENCHMARK_TABLE_NAME}"    # DynamoDB table name

# local environment variables (for use in function/subshells)
export STAGE_SHORT_NAME=$1              # name of this stage (one word)

# initialize stage_json
stage_json=$(cat << EOF
{
    "M": {
        "Name": { "S": "${STAGE_SHORT_NAME}" },
        "Completed": {"BOOL": false },
        "Log": {"S": "" },
        "Artifacts": {"L": [] }
    }
}
EOF
)

function db_query_stage_is_completed() {
    # return code: 0 if the stage is previously completed, otherwise non-zero
    aws dynamodb get-item \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
        --attributes-to-get "Stages" \
    | jq -e ".Item.Stages.L[] | select((.M.Name.S == \"${STAGE_SHORT_NAME}\") and (.M.Completed.BOOL == true))" &> /dev/null
}

function db_get_stage_index() {
    # return code: 0 if the stage is registerd, otherwise non-zero
    # stdout: the stage's index
    aws dynamodb get-item \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
        --attributes-to-get "Stages" \
    | jq -e ".Item.Stages.L | map(.M.Name.S == \"${STAGE_SHORT_NAME}\") | index(true)"
}

function db_update_stage() {
    if stage_index=$(db_get_stage_index) ; then
        # stage exist in db
        update_expression="SET #s[${stage_index}] = :val"
        expression_attribute_values="{\":val\": ${stage_json} }"
    else
        # stage doesn't exist in db
        update_expression="SET #s = list_append(#s, :val)"
        expression_attribute_values="{\":val\":{\"L\":[ ${stage_json} ]}}"
    fi
    aws dynamodb update-item \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
        --update-expression "${update_expression}" \
        --expression-attribute-names '{"#s": "Stages"}' \
        --expression-attribute-values "${expression_attribute_values}"
}

function upload_artifacts() {
    # arguments: artifact_name file1 [file2..]
    artifact_file_name=${STAGE_SHORT_NAME}_${1}.tar.gz
    artifact_uri=${GEOSCHEM_BENCHMARK_S3_BUCKET}/${GEOSCHEM_BENCHMARK_INSTANCE_ID}/${artifact_file_name}
    shift
    tar -cvzf ${artifact_file_name} $@
    aws s3 cp ${artifact_file_name} ${artifact_uri} --only-show-errors
    stage_json=$(echo "${stage_json}" | jq ".M.Artifacts.L[.M.Artifacts.L | length] |= . + {\"S\": \"${artifact_uri}\"}")
}
export -f upload_artifacts

function download_artifacts() {
    artifacts=$(
        aws dynamodb get-item \
            --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
            --key "{\"InstanceID\": {\"S\": \"${GEOSCHEM_BENCHMARK_INSTANCE_ID}\"}}" \
            --attributes-to-get "Stages" \
        | jq -r ".Item.Stages.L[] | select(.M.Name.S != \"${STAGE_SHORT_NAME}\") | .M.Artifacts.L[].S"
    )
    for artifact_uri in ${artifacts}; do
        aws s3 cp ${artifact_uri} artifact.tar.gz --only-show-errors
        tar -xvzf artifact.tar.gz
        rm -f artifact.tar.gz
    done
}

function upload_log_file() {
    # arguments: log_file
    log_file_name=${1}
    log_file_uri=${GEOSCHEM_BENCHMARK_S3_BUCKET}/${GEOSCHEM_BENCHMARK_INSTANCE_ID}/${log_file_name}
    aws s3 cp ${log_file_name} ${log_file_uri} --only-show-errors
    stage_json=$(echo "${stage_json}" | jq ".M.Log.S=\"${log_file_uri}\"")
}

# runStage.sh logic
if ! db_query_stage_is_completed ; then
    # change to temporary directory
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}

    # redirect stdout and stderr to log file
    log_file=${STAGE_SHORT_NAME}.txt
    exec > >(tee -i ${log_file})
    exec 2>&1
    echo "Running '${STAGE_SHORT_NAME}' in ${GEOSCHEM_BENCHMARK_WORKING_DIR}"

    # tasks before the stage runs
    db_update_stage     # set empty
    download_artifacts

    # use an exit trap to upload the log file, update the database, and remove the temporary files
    function exit_hook() {
        if [ "$1" -eq "0" ]; then
            # stage script exited successfully
            stage_json=$(echo "${stage_json}" | jq ".M.Completed.BOOL=true")
        fi
        upload_log_file ${log_file}
        db_update_stage
        
        # Clean up temporary files
        exec &>/dev/null

        cd ${TMPDIR}
        rm -rf ${temp_dir}
    }
    trap 'exit_hook $?' EXIT

else 
    echo "Skipping '${STAGE_SHORT_NAME}' (already completed)"
    cd ${TMPDIR}
    rm -rf ${temp_dir}
    exit 0
fi
