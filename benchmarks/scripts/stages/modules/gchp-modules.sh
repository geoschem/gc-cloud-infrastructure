#!/usr/bin/env bash

function download_code() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    git clone https://github.com/geoschem/GCHP.git
    cd GCHP
    git checkout ${GEOSCHEM_BENCHMARK_COMMIT_ID}
    git submodule update --init --recursive --depth 1
}


function create_run_directory() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    cd GCHP/run
    ./createRunDir.sh << EOF
${GEOSCHEM_BENCHMARK_EXTDATA_DIR}
1
2
1
${GEOSCHEM_BENCHMARK_WORKING_DIR}
run-directory
n
EOF
}

function configure_run_directory() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}/run-directory
    case ${GEOSCHEM_BENCHMARK_SITE} in
        WUSTL)
            site_default_cores_per_node=30
            ;;
        AWS)
            site_default_cores_per_node=36
            ;;
        *)
            >&2 echo "error: unknown site '${GEOSCHEM_BENCHMARK_SITE}' (GEOSCHEM_BENCHMARK_SITE)"
            exit 1
            ;;
    esac
    # set defaults
    GEOSCHEM_BENCHMARK_NUM_NODES=${GEOSCHEM_BENCHMARK_NUM_NODES:=2}
    GEOSCHEM_BENCHMARK_PROC_PER_NODE=${GEOSCHEM_BENCHMARK_PROC_PER_NODE:=${site_default_cores_per_node}}
    GEOSCHEM_BENCHMARK_NUM_PROC=$(( GEOSCHEM_BENCHMARK_NUM_NODES * GEOSCHEM_BENCHMARK_PROC_PER_NODE ))
    GEOSCHEM_BENCHMARK_RESOLUTION=${GEOSCHEM_BENCHMARK_RESOLUTION:=48}
    GEOSCHEM_BENCHMARK_START_DATE=${GEOSCHEM_BENCHMARK_START_DATE:=20190701}
    GEOSCHEM_BENCHMARK_END_DATE=${GEOSCHEM_BENCHMARK_END_DATE:=20190801}
    GEOSCHEM_BENCHMARK_DURATION=${GEOSCHEM_BENCHMARK_DURATION:=00000100}
    GEOSCHEM_BENCHMARK_DURATION_HOURS=${GEOSCHEM_BENCHMARK_DURATION_HOURS:=000000}
    GEOSCHEM_BENCHMARK_FREQUENCY=${GEOSCHEM_BENCHMARK_FREQUENCY:=7440000}
    GEOSCHEM_BENCHMARK_MONTHLY_DIAGS=${GEOSCHEM_BENCHMARK_MONTHLY_DIAGS:=1}

    # Changes based on version
    GC_VERSION=$(echo ${GEOSCHEM_BENCHMARK_INSTANCE_ID} | sed "s#^[^-]*-[^-]*-[^-]*-##" | sed "s#[.].*##")
    if [[ "x${GC_VERSION}" == "x13" ]]; then
        sed -i "s/TOTAL_CORES=.*/TOTAL_CORES=${GEOSCHEM_BENCHMARK_NUM_PROC}/" runConfig.sh
        sed -i "s/NUM_NODES=.*/NUM_NODES=${GEOSCHEM_BENCHMARK_NUM_NODES}/" runConfig.sh
        sed -i "s/NUM_CORES_PER_NODE=.*/NUM_CORES_PER_NODE=${GEOSCHEM_BENCHMARK_PROC_PER_NODE}/" runConfig.sh
        sed -i "s/CS_RES=48/CS_RES=${GEOSCHEM_BENCHMARK_RESOLUTION}/" runConfig.sh
        sed -i "s/Start_Time=\"[0-9][0-9]* 000000\"/Start_Time=\"${GEOSCHEM_BENCHMARK_START_DATE} 000000\"/" runConfig.sh
        sed -i "s/End_Time=\"[0-9][0-9]* 000000\"/End_Time=\"${GEOSCHEM_BENCHMARK_END_DATE} ${GEOSCHEM_BENCHMARK_DURATION_HOURS}\"/" runConfig.sh
        sed -i "s/Duration=\"[0-9][0-9]* 000000\"/Duration=\"${GEOSCHEM_BENCHMARK_DURATION} ${GEOSCHEM_BENCHMARK_DURATION_HOURS}\"/" runConfig.sh
        sed -i "s/timeAvg_freq=\"[0-9][0-9]*\"/timeAvg_freq=\"${GEOSCHEM_BENCHMARK_FREQUENCY}\"/" runConfig.sh
        sed -i "s/timeAvg_dur=\"[0-9][0-9]*\"/timeAvg_dur=\"${GEOSCHEM_BENCHMARK_FREQUENCY}\"/" runConfig.sh
        sed -i "s/timeAvg_monthly=\"1\"/timeAvg_monthly=\"$GEOSCHEM_BENCHMARK_MONTHLY_DIAGS\"/" runConfig.sh

        # reconfigure
        ./runConfig.sh --silent || echo 'Ignoring error in runConfig.sh'
    else 
        # make edits
        sed -i "s/TOTAL_CORES=.*/TOTAL_CORES=${GEOSCHEM_BENCHMARK_NUM_PROC}/" setCommonRunSettings.sh
        sed -i "s/NUM_NODES=.*/NUM_NODES=${GEOSCHEM_BENCHMARK_NUM_NODES}/" setCommonRunSettings.sh
        sed -i "s/NUM_CORES_PER_NODE=.*/NUM_CORES_PER_NODE=${GEOSCHEM_BENCHMARK_PROC_PER_NODE}/" setCommonRunSettings.sh
        sed -i "s/CS_RES=48/CS_RES=${GEOSCHEM_BENCHMARK_RESOLUTION}/" setCommonRunSettings.sh
        sed -i "s/Run_Duration=\"[0-9][0-9]* 000000\"/Run_Duration=\"${GEOSCHEM_BENCHMARK_DURATION} ${GEOSCHEM_BENCHMARK_DURATION_HOURS}\"/" setCommonRunSettings.sh
        sed -i "s/Diag_Frequency=\"[0-9][0-9]*\"/Diag_Frequency=\"${GEOSCHEM_BENCHMARK_FREQUENCY}\"/" setCommonRunSettings.sh
        sed -i "s/Diag_Duration=\"[0-9][0-9]*\"/Diag_Duration=\"${GEOSCHEM_BENCHMARK_FREQUENCY}\"/" setCommonRunSettings.sh
        sed -i "s/Diag_Monthly=\"1\"/Diag_Monthly=\"$GEOSCHEM_BENCHMARK_MONTHLY_DIAGS\"/" setCommonRunSettings.sh
        sed -i "s/AutoUpdate_Diagnostics=OFF/AutoUpdate_Diagnostics=ON/" setCommonRunSettings.sh
        sed -i "s/[0-9][0-9]* 000000/${GEOSCHEM_BENCHMARK_START_DATE} 000000/" cap_restart
        
        # reconfigure
        ./setCommonRunSettings.sh || echo 'Ignoring error in setCommonRunSettings.sh'
        ./setRestartLink.sh
    fi
}

function install_geoschem_to_run_directory() {
    cd ${GEOSCHEM_BENCHMARK_WORKING_DIR}
    mkdir build
    cd build
    cmake ${GEOSCHEM_BENCHMARK_WORKING_DIR}/GCHP -DRUNDIR=${GEOSCHEM_BENCHMARK_WORKING_DIR}/run-directory
    make -j4 install
}
