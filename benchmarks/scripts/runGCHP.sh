#!/usr/bin/env bash
# setup environment
err=0
trap 'err=1' ERR
source /environments/gchp_source.env

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
echo "downloading input data"
if [ $INPUT_DATA_DOWNLOAD -gt 0 ]
then
    echo "running bashdatacatalog"
    cd /home/ExtData
    mkdir catalogs
    cd catalogs
    # TODO replace hardcoded path
    wget -r -nH --cut-dirs=3 -np -A "*.csv" geoschemdata.wustl.edu/ExtData/DataCatalogs/13.3/
    rm InitialConditions.csv # restarts are too big
    cd ..
    bashdatacatalog catalogs/*.csv fetch

    if [[ "x${TIME_PERIOD}" == "x1Day" ]]; then
      echo "downloading data for 1Day time period"
      bashdatacatalog catalogs/*.csv list-missing relative 2019-06-30 2019-07-02 \
      | sed 's#./\(.*\)#aws s3 cp s3://gcgrid/\1 /home/ExtData/\1 --request-payer#g' \
      | bash
    else
      echo "downloading data for 1Mon time period"
      bashdatacatalog catalogs/*.csv list-missing relative 2019-06-30 2019-08-01 \
      | sed 's#./\(.*\)#aws s3 cp s3://gcgrid/\1 /home/ExtData/\1 --request-payer#g' \
      | bash
    fi
fi
echo "finished downloading input data"

cd $RUNDIR
# create a symlinks
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
echo "uploading output dir"
aws s3 cp gchp.log "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/OutputDir/gchp.log"
aws s3 cp HEMCO.log "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/OutputDir/HEMCO.log"
aws s3 cp OutputDir/ "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/OutputDir" --recursive
echo "finished uploading output dir"

test $err = 0 # Return non-zero if any command failed
exit $err