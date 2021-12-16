#!/usr/bin/env bash
# Description: This script is designed for automated benchmarking on aws 
# within a docker container deployed by aws batch. It will download a given 
# GCC run directory from s3, download the necessary input data for the time 
# period specified, run the simulation, and upload the output to s3. 

# setup environment
err=0
trap 'err=1' ERR
source /environments/gchp_source.env

# set default paths
REPO_PATH="/gc-src"
RUNDIR="/home/default_rundir"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCC $REPO_PATH

mkdir /home/ExtData
# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/rundir" $RUNDIR --recursive --quiet
echo "finished downloading run directory from s3"

# get input data
cd $RUNDIR
/scripts/utils/get-input-data.sh GCC

# create a symlinks
ln -s "$REPO_PATH/" CodeDir

# execute scripts
echo "running gcclassic"
./gcclassic | tee gcclassic.log
echo "finished running gcclassic"

# upload result 
echo "uploading output dir"
aws s3 cp gcclassic.log "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/OutputDir/gcclassic.log"
aws s3 cp HEMCO.log "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/OutputDir/HEMCO.log"
aws s3 cp OutputDir/ "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/OutputDir" --recursive
echo "finished uploading output dir"
test $err = 0 # Return non-zero if any command failed
exit $err
