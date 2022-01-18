#!/usr/bin/env bash
set -u
set -e

item=$(cat << EOF
{
    "InstanceID": {"S":"${GEOSCHEM_BENCHMARK_INSTANCE_ID}"},
    "Site": {"S":"${GEOSCHEM_BENCHMARK_SITE}"},
    "StagesCompleted": {"L": []},
    "Artifacts": {"S":"s3://washu-benchmarks-cloud/${GEOSCHEM_BENCHMARK_INSTANCE_ID}/artifacts"},
    "StagesCompleted": {"L": []},
}
EOF
)

aws dynamodb put-item \
    --table-name geoschem_testing \
    --item "${item}"
