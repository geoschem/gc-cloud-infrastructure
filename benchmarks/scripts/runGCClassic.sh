#!/usr/bin/env bash
# Description: This script is designed for automated benchmarking on aws 
# within a docker container deployed by aws batch. It will download a given 
# GCC run directory from s3, download the necessary input data for the time 
# period specified, run the simulation, and upload the output to s3. 

report() {
  err=1
  echo -n "error at line ${BASH_LINENO[0]}, in call to "
  sed -n ${BASH_LINENO[0]}p $0
} >&2

err=0
trap report ERR

# setup environment
source /environments/gchp_source.env

# set default paths
REPO_PATH="/gc-src"
RUNDIR="/home/default_rundir"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCC $REPO_PATH

mkdir /home/ExtData
# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp "${S3_RUNDIR_PATH}${TIME_PERIOD}/${TAG_NAME}/GCC/rundir" $RUNDIR --recursive --only-show-errors
echo "finished downloading run directory from s3"

# get input data
cd $RUNDIR
/scripts/utils/get-input-data.sh GCC

# create a symlinks
ln -s "$REPO_PATH/" CodeDir

# execute scripts
echo "running gcclassic"
time ./gcclassic | tee gcclassic.log
echo "finished running gcclassic"

# move needed files to output dir
mv GEOSChem.Restart.* OutputDir/
mv gcclassic.log OutputDir/gcclassic.log
mv HEMCO.log OutputDir/HEMCO.log

# upload result 
echo "uploading output dir"
aws s3 cp OutputDir/ "${S3_RUNDIR_PATH}${TIME_PERIOD}/${TAG_NAME}/GCC/OutputDir" --recursive
echo "finished uploading output dir"
exit $err
