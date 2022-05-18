#!/usr/bin/env bash

function download_code() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    git clone https://github.com/geoschem/GCClassic.git
    cd GCClassic
    git checkout ${GEOSCHEM_BENCHMARK_COMMIT_ID}
    git submodule update --init --recursive --depth 1
}

function create_run_directory() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    cd GCClassic/run
    ./createRunDir.sh << EOF 
${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
1
2
1
1
1
${GEOSCHEM_BENCHMARK_WORKING_DIR}
run-directory
n
EOF
}

function configure_run_directory() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}/run-directory
    # set defaults
    GEOSCHEM_BENCHMARK_NUM_NODES=${GEOSCHEM_BENCHMARK_NUM_NODES:=2}
    GEOSCHEM_BENCHMARK_RESOLUTION=${GEOSCHEM_BENCHMARK_RESOLUTION:=48}
    GEOSCHEM_BENCHMARK_START_DATE=${GEOSCHEM_BENCHMARK_START_DATE:=20190701}
    GEOSCHEM_BENCHMARK_END_DATE=${GEOSCHEM_BENCHMARK_END_DATE:=20190801}
    GEOSCHEM_BENCHMARK_DURATION=${GEOSCHEM_BENCHMARK_DURATION:=00000100}
    GEOSCHEM_BENCHMARK_DURATION_HOURS=${GEOSCHEM_BENCHMARK_DURATION_HOURS:=000000}
    GEOSCHEM_BENCHMARK_FREQUENCY=${GEOSCHEM_BENCHMARK_FREQUENCY:=7440000}
    GEOSCHEM_BENCHMARK_MONTHLY_DIAGS=${GEOSCHEM_BENCHMARK_MONTHLY_DIAGS:=1}
    
    # Check whether to use input.geos (for versions <14)
    GC_VERSION=$(echo ${GEOSCHEM_BENCHMARK_INSTANCE_ID} | sed "s#^[^-]*-[^-]*-[^-]*-##" | sed "s#[.].*##")
    if [[ "x${GC_VERSION}" == "x13" ]]; then
        sed -i "s/Start   YYYYMMDD, hhmmss  : [0-9][0-9]* 000000/Start   YYYYMMDD, hhmmss  : ${GEOSCHEM_BENCHMARK_START_DATE} 000000/" input.geos
        sed -i "s/End   YYYYMMDD, hhmmss  : [0-9][0-9]* 000000/End   YYYYMMDD, hhmmss  : ${GEOSCHEM_BENCHMARK_END_DATE} ${GEOSCHEM_BENCHMARK_DURATION_HOURS}/" input.geos
    else
        sed -i "s#start_date\: \[20190701, 000000\]#start_date\: \[${GEOSCHEM_BENCHMARK_START_DATE}, 000000\]#" geoschem_config.yml
        sed -i "s#end_date\: \[20190801, 000000\]#end_date\: \[${GEOSCHEM_BENCHMARK_END_DATE}, ${GEOSCHEM_BENCHMARK_DURATION_HOURS}\]#" geoschem_config.yml
    fi

    # reset DiagnFreq based on time period
    if [[ "x${GEOSCHEM_BENCHMARK_TIME_PERIOD}" == "x1Day" ]] ||
    [[ "x${GEOSCHEM_BENCHMARK_TIME_PERIOD}" == "x1Hr" ]]; then
        echo "creating rundir for 1Day time period"
        sed -i "s/DiagnFreq:                   Monthly/DiagnFreq:                   End/" HEMCO_Config.rc
        sed -i "s/00000100 000000/'End'/g" HISTORY.rc
    fi
}

function install_geoschem_to_run_directory() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}/run-directory/build
    cmake ../CodeDir
    cmake . -DRUNDIR=".."
    make -j
    make install
}
