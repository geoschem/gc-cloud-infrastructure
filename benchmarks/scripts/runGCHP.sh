#!/usr/bin/env bash
# Description: This script is designed for automated benchmarking on aws 
# within a docker container deployed by aws batch. It will download a given 
# GCHP run directory from s3, download the necessary input data for the time 
# period specified, run the simulation, and upload the output to s3.
report() {
  err=1
  echo -n "error at line ${BASH_LINENO[0]}, in call to "
  sed -n ${BASH_LINENO[0]}p $0
} >&2

# reduce number of nodes by 6 to fix issue running with docker
export NUM_CORES_PER_NODE="$(($NUM_CORES_PER_NODE-6))"
export TOTAL_CORES="$(($TOTAL_CORES-6))"

err=0
trap report ERR

# setup environment
source /etc/bashrc

# set default paths
REPO_PATH="/gc-src"
RUNDIR="/home/default_rundir"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCHP $REPO_PATH

mkdir /home/ExtData
# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp "${S3_RUNDIR_PATH}${TIME_PERIOD}/${TAG_NAME}/GCHP/rundir/" $RUNDIR --recursive --only-show-errors
echo "finished downloading run directory from s3"

# get input data
if [ $INPUT_DATA_DOWNLOAD -gt 0 ]; then
  # TODO remove this
  /scripts/utils/get-input-data.sh GCHP /home/ExtData
  aws s3 cp "s3://gcgrid/GEOSCHEM_RESTARTS/GC_13.0.0/GCHP.Restart.fullchem.20190701_0000z.c${CS_RES}.nc4" "/home/ExtData/GEOSCHEM_RESTARTS/GC_13.0.0/GCHP.Restart.fullchem.20190701_0000z.c${CS_RES}.nc4" --request-payer
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
# TODO move this somewher else
sed -i "s/nCores=6/nCores=${NUM_CORES_PER_NODE}/" gchp.cloud.run


# execute scripts
chmod +x runConfig.sh gchp.cloud.run gchp
./runConfig.sh
echo "running gchp"
./gchp.cloud.run
echo "finished running gchp"

# move needed files to output dir
mv GEOSChem.Restart.* OutputDir/
mv gchp.log OutputDir/gchp.log
mv HEMCO.log OutputDir/HEMCO.log

# upload result
echo "uploading output dir"
aws s3 cp OutputDir/ "${S3_RUNDIR_PATH}${TIME_PERIOD}/${TAG_NAME}/GCHP/OutputDir" --recursive
echo "finished uploading output dir"
exit $err