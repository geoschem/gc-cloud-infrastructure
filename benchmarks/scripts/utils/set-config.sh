#!/usr/bin/env bash

# Description: Helper script to handle the setting of configuration files for GCC
# and GCHP
#
# Usage:
#   ./set-config.sh <simulation-type> <rundir-path>
#       simulation-type: either GCC or GCHP. Determines which git repo to clone
#       rundir-path: path to rundir
trap 'echo "Error in set-config.sh"' ERR
cd $2
echo "File added to prevent s3 auto deletion of empty OutputDir" > "$2/OutputDir/README.md"

echo "Setting simulation settings for $1"

# GCHP configuration settings
if [[ "x$1" == "xGCHP" ]]; then
  # set cores and resolution
  sed -i "s/TOTAL_CORES=96/TOTAL_CORES=${TOTAL_CORES}/" runConfig.sh
  sed -i "s/NUM_NODES=2/NUM_NODES=${NUM_NODES}/" runConfig.sh
  sed -i "s/CS_RES=48/CS_RES=${CS_RES}/" runConfig.sh
  sed -i "s/NUM_CORES_PER_NODE=48/NUM_CORES_PER_NODE=${NUM_CORES_PER_NODE}/" runConfig.sh

  # check what time period to use -- default is 1Mon
  if [[ "x${TIME_PERIOD}" == "x1Day" ]]; then
    echo "creating rundir for 1Day time period"
    sed -i 's/End_Time="20190801 000000"/End_Time="20190702 000000"/' runConfig.sh
    sed -i 's/Duration="00000100 000000"/Duration="00000001 000000"/' runConfig.sh
  fi

# GCClassic configuration settings
elif [[ "x$1" == "xGCC" ]]; then
  # check what time period to use -- default is 1Mon
  if [[ "x${TIME_PERIOD}" == "x1Day" ]]; then
    echo "creating rundir for 1Day time period"
    sed -i "s/End   YYYYMMDD, hhmmss  : 20190801 000000/End   YYYYMMDD, hhmmss  : 20190702 000000/" input.geos
    sed -i "s/DiagnFreq:                   Monthly/DiagnFreq:                   End/" HEMCO_Config.rc
    sed -i "s/00000100 000000/'End'/g" HISTORY.rc
  fi
else
  echo "ERROR: Invalid parameter for simulation type given: $1"
  exit 1
fi
