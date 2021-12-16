#!/usr/bin/env bash
# Description: This script is designed for automated benchmarking on aws 
# within a docker container deployed by aws batch. It will download a given 
# GCHP run directory from s3, download the necessary input data for the time 
# period specified, run the simulation, and upload the output to s3.

# setup environment
err=0
trap 'err=1' ERR
source /environments/gchp_source.env

# set default paths
REPO_PATH="/gc-src"
RUNDIR="/home/default_rundir"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCHP $REPO_PATH

mkdir /home/ExtData
# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/rundir/" $RUNDIR --recursive --quiet
echo "finished downloading run directory from s3"

# get input data
if [ $INPUT_DATA_DOWNLOAD -gt 0 ]; then
  /scripts/utils/get-input-data.sh GCHP /home/ExtData
fi

# create a symlinks
cd $RUNDIR
ln -s "/home/ExtData/GEOSCHEM_RESTARTS/GC_13.0.0/GCHP.Restart.fullchem.20190701_0000z.c${CS_RES}.nc4" "initial_GEOSChem_rst.c${CS_RES}_fullchem.nc"
ln -s /home/ExtData/GEOS_0.5x0.625/MERRA2/ MetDir
ln -s /home/ExtData/HEMCO/ HcoDir
ln -s "$REPO_PATH/" CodeDir
ln -s /home/ExtData/CHEM_INPUTS/ ChemDir
ln -s /environments/gchp_source.env gchp.env

# copy over local run script
cp /scripts/gchp.cloud.run gchp.cloud.run

# execute scripts
chmod +x runConfig.sh gchp.cloud.run gchp
./runConfig.sh
echo "running gchp"
./gchp.cloud.run
echo "finished running gchp"

# upload result
echo "uploading output dir"
aws s3 cp gchp.log "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/OutputDir/gchp.log"
aws s3 cp HEMCO.log "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/OutputDir/HEMCO.log"
aws s3 cp OutputDir/ "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/OutputDir" --recursive
echo "finished uploading output dir"

test $err = 0 # Return non-zero if any command failed
exit $err