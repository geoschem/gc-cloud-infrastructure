#!/usr/bin/env bash
set -u
set -e

# required variables
: "${GEOSCHEM_BENCHMARK_INSTANCE_ID}"
: "${GEOSCHEM_BENCHMARK_SITE}"
: "${GEOSCHEM_BENCHMARK_TABLE_NAME}"
: "${GEOSCHEM_BENCHMARK_S3_BUCKET}"
: "${GEOSCHEM_BENCHMARK_INSTANCE_DESCRIPTION}"

item=$(cat << EOF
{
    "InstanceID": {"S":"${GEOSCHEM_BENCHMARK_INSTANCE_ID}"},
    "Site": {"S":"${GEOSCHEM_BENCHMARK_SITE}"},
    "Stages": {"L": [] },
    "ExecStatus": {"S": "PENDING" },
    "Description": {"S": "${GEOSCHEM_BENCHMARK_INSTANCE_DESCRIPTION}" },
    "CreationDate": {"S": "$(date --iso-8601)" },
    "S3Uri": {"S": "${GEOSCHEM_BENCHMARK_S3_BUCKET}/${GEOSCHEM_BENCHMARK_INSTANCE_ID}" }
}
EOF
)

set -x
aws dynamodb put-item \
    --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
    --item "${item}" \
    --condition-expression "attribute_not_exists(InstanceID)"
