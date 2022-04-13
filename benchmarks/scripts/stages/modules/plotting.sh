#!/bin/bash

# returns whether primary key exists and given stage ran successfully
function primary_key_exists() {
    local primary_key=$1
    local stage_name=$2

    local simulation_status=`aws dynamodb get-item \
    --table-name geoschem_testing \
    --key "{\"InstanceID\": {\"S\": \"${primary_key}\"}}" \
    --output json`

    # Check if the non-dev model's simulation exists and was successful
    if [[ `echo $simulation_status | jq '.Item.ExecStatus.S | contains("SUCCESSFUL")'` == "true" ]] \
    && [[ `echo $simulation_status | jq --arg name $stage_name 'any(.Item.Stages.L[].M.Name.S; . == $name)'` == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# extrapolate based on GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY to 
# create model comparison plot with corresponding 1Mon benchmark
function run_model_comparison() {
    case ${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE} in
        gchp)
            export GEOSCHEM_BENCHMARK_REF_MODEL_TYPE=gcc
            export GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY=$(echo $GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY | sed "s#${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}#${GEOSCHEM_BENCHMARK_REF_MODEL_TYPE}#")
            SIMULATION_STAGE_NAME=RunGCC
            ;;
        gcc)
            export GEOSCHEM_BENCHMARK_REF_MODEL_TYPE=gchp
            export GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY=$(echo $GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY | sed "s#${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}#${GEOSCHEM_BENCHMARK_REF_MODEL_TYPE}#")
            SIMULATION_STAGE_NAME=RunGCHP
            ;;
        *)
            >&2 echo "error: unknown dev model type '${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}' extrapolated from prefix of primary key: ${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"
            exit 1
            ;;
    esac
    export GEOSCHEM_BENCHMARK_COMPARISON_TYPE=gchp_gcc
    export GEOSCHEM_BENCHMARK_INSTANCE_DESCRIPTION="${GEOSCHEM_BENCHMARK_TIME_PERIOD} Benchmark plot model comparison ('${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}'; '${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}')"
    export GEOSCHEM_BENCHMARK_INSTANCE_ID=diff-${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}-${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}

    # Check if the non-dev model's simulation exists and was successful
    if [[ $(primary_key_exists ${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY} ${SIMULATION_STAGE_NAME}) == "true" ]]; then
        ./helpers/dbCreateTest.sh || echo "Test already exists"
        ./stages/createBenchmarkPlots.sh
        echo "Finished $GEOSCHEM_BENCHMARK_INSTANCE_ID model comparison."
    else
        echo "Skipping ${GEOSCHEM_BENCHMARK_COMPARISON_TYPE} model comparison. '${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}' either does not yet exist or failed to run."
    fi
}

function run_diff_of_diffs() {
    case ${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE} in
        gchp)
            diff_model_type=gcc
            ;;
        gcc)
            export diff_model_type=gchp
            ;;
        *)
            >&2 echo "error: unknown dev model type '${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}' extrapolated from prefix of primary key: ${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"
            exit 1
            ;;
    esac

    # extrapolate using dev and ref primary keys to get diff primary keys
    export GEOSCHEM_BENCHMARK_DIFF_DEV_PRIMARY_KEY=$(echo $GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY | sed "s#${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}#${diff_model_type}#")
    export GEOSCHEM_BENCHMARK_DIFF_REF_PRIMARY_KEY=$(echo $GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY | sed "s#${GEOSCHEM_BENCHMARK_REF_MODEL_TYPE}#${diff_model_type}#")
    
    ref_commit=$(echo $GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY | sed 's#.*[0-9][a-zA-Z]..-##')
    dev_commit=$(echo $GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY | sed 's#.*[0-9][a-zA-Z]..-##')
    dev_prefix=$(echo $GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY | sed 's#-[0-9][a-zA-Z].*##')
    ref_diff_prefix=$(echo $GEOSCHEM_BENCHMARK_DIFF_REF_PRIMARY_KEY | sed 's#-[0-9][a-zA-Z].*##')
    export GEOSCHEM_BENCHMARK_COMPARISON_TYPE=diff_of_diffs
    export GEOSCHEM_BENCHMARK_INSTANCE_DESCRIPTION="${GEOSCHEM_BENCHMARK_TIME_PERIOD} Benchmark plot diff of diffs (ref: '${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}'; dev: '${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}'; dev: '${GEOSCHEM_BENCHMARK_DIFF_DEV_PRIMARY_KEY}'; ref: '${GEOSCHEM_BENCHMARK_DIFF_REF_PRIMARY_KEY})"
    export GEOSCHEM_BENCHMARK_INSTANCE_ID=diff-of-diffs-${GEOSCHEM_BENCHMARK_TIME_PERIOD}-${dev_prefix}-${ref_diff_prefix}-${ref_commit}-${dev_commit}

    case ${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE} in
        gchp)
            SIMULATION_STAGE_NAME=RunGCC
            export GEOSCHEM_BENCHMARK_DIFF_TYPE=gcc
            ;;
        gcc)
            export GEOSCHEM_BENCHMARK_DIFF_TYPE=gchp
            SIMULATION_STAGE_NAME=RunGCHP
            ;;
        *)
            >&2 echo "error: unknown dev model type '${GEOSCHEM_BENCHMARK_DEV_MODEL_TYPE}' extrapolated from prefix of primary key: ${GEOSCHEM_BENCHMARK_DEV_PRIMARY_KEY}"
            exit 1
            ;;
    esac

    # check if necessary primary keys exist
    if [[ $(primary_key_exists ${GEOSCHEM_BENCHMARK_DIFF_DEV_PRIMARY_KEY} ${SIMULATION_STAGE_NAME}) == "true" ]] \
        && [[ $(primary_key_exists ${GEOSCHEM_BENCHMARK_DIFF_REF_PRIMARY_KEY} ${SIMULATION_STAGE_NAME}) == "true" ]]; then
        ./helpers/dbCreateTest.sh || echo "Test already exists"
        ./stages/createBenchmarkPlots.sh
        echo "Finished $GEOSCHEM_BENCHMARK_INSTANCE_ID $GEOSCHEM_BENCHMARK_COMPARISON_TYPE model comparison."
    else
        echo "Skipping ${GEOSCHEM_BENCHMARK_COMPARISON_TYPE}. '${GEOSCHEM_BENCHMARK_REF_PRIMARY_KEY}' either does not yet exist or failed to run."
    fi
}
