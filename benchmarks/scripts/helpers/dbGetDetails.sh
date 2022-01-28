#!/bin/bash

set -e
set -u

primary_key=$1  # primary key of the entry you want to look up

# todo: Fix this savage command. It's supposed to print a database entry in a semi human readable way until we come up with a dashboard.
aws dynamodb query \
    --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
    --key-condition-expression 'InstanceID = :v' \
    --expression-attribute-values "{\":v\": {\"S\": \"${primary_key}\"}}" \
    --projection-expression "Stages" | jq '.Items[0].Stages.L[] | { Name:.M.Name.S, Completed:.M.Completed.BOOL, Log:.M.Log.S,  StartTime:.M.StartTime.S, EndTime:.M.EndTime.S, PublicArtifacts:  [ .M.PublicArtifacts.L | .[].S ]}'
