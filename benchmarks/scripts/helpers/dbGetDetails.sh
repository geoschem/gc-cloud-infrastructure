#!/bin/bash

set -e
set -u

instance_id=$1

aws dynamodb query \
    --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
    --key-condition-expression 'InstanceID = :v' \
    --expression-attribute-values "{\":v\": {\"S\": \"${instance_id}\"}}" \
    --projection-expression "Stages" | jq '.Items[0].Stages.L[] | { Name:.M.Name.S, Completed:.M.Completed.BOOL, Log:.M.Log.S,  StartTime:.M.StartTime.S, EndTime:.M.EndTime.S, PublicArtifacts:  [ .M.PublicArtifacts.L | .[].S ]}'
