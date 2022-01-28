#!/bin/bash

set -e
set -u

function scan_table() {
    aws dynamodb scan \
        --table-name ${GEOSCHEM_BENCHMARK_TABLE_NAME} \
        --projection-expression 'InstanceID, CreationDate, ExecStatus, Description'
}

function convert_scan_output_to_csv() {
    jq -e -r '.Items[] | [.InstanceID.S, .CreationDate.S, .ExecStatus.S, .Description.S] | @csv'
}

function sort_csv() {
    sort -r -k 2,2 -k 1,1 -t,
}

function format_table() {
    sed 's#"##g' | column -t -s','
}

{ 
    echo "InstanceID,CreationDate,ExecStatus,Description"; 
    ( scan_table | convert_scan_output_to_csv | sort_csv) 
} | format_table

