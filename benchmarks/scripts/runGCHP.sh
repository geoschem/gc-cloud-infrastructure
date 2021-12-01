#!/usr/bin/env bash
# setup environment
err=0
trap 'err=1' ERR
cd /
source /environments/gchp_source.env

if [[ ! -z "${TAG_NAME}" ]]; then
  rm -rf /gc-src
  git clone https://github.com/geoschem/GCHP.git /gc-src
  cd /gc-src
  git checkout ${TAG_NAME}
  git submodule update --init --recursive
fi

mkdir /home/ExtData
SKIP_INPUT_DATA_DOWNLOAD=1
# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/rundir/" /home/default_rundir --recursive --quiet
echo "finished downloading run directory from s3"

# get input data
echo "downloading input data"
aws s3 cp s3://benchmarks-cloud/ExtData/ /home/ExtData/ --quiet --recursive
if [ $SKIP_INPUT_DATA_DOWNLOAD -gt 0 ]
then
    echo "running bashdatacatalog"
    cd /home/ExtData
    mkdir catalogs
    cd catalogs
    # TODO replace hardcoded path
    wget -r -nH --cut-dirs=3 -np -A "*.csv" geoschemdata.wustl.edu/ExtData/DataCatalogs/13.2/
    rm InitialConditions.csv # restarts are too big
    cd ..
    bashdatacatalog catalogs/*.csv fetch
    bashdatacatalog catalogs/*.csv list-missing relative 2019-06-30 2019-08-01 \
     | sed 's#./\(.*\)#aws s3 cp s3://benchmarks-cloud/ExtData/\1 /home/ExtData/\1#g' \ 
     | bash
    # for catalog in `ls *.csv`; do
    #     echo "fetching input data for catalog: $catalog"
    #     bashdatacatalog $catalog fetch
    #     # bashdatacatalog $catalog list-missing url 2019-06-30 2019-08-02 > download_list.txt
    #     # wget -nH -x --cut-dirs=1 --input-file=download_list.txt
    # done
fi
echo "finished downloading input data"

cd /home/default_rundir
# create a symlinks
ln -s "/home/ExtData/GEOSCHEM_RESTARTS/GC_13.0.0/GCHP.Restart.fullchem.20190701_0000z.c${CS_RES}.nc4" "initial_GEOSChem_rst.c${CS_RES}_fullchem.nc"
ln -s /home/ExtData/GEOS_0.5x0.625/MERRA2/ MetDir
ln -s /home/ExtData/HEMCO/ HcoDir
ln -s /gc-src/ CodeDir
ln -s /home/ExtData/CHEM_INPUTS/ ChemDir
ln -s /gchp_source.env gchp.env

# copy over local run script
cp /scripts/gchp.cloud.run gchp.cloud.run

# configure runConfig
sed -i "s/TOTAL_CORES=96/TOTAL_CORES=${TOTAL_CORES}/" runConfig.sh
sed -i "s/NUM_NODES=2/NUM_NODES=${NUM_NODES}/" runConfig.sh
sed -i "s/CS_RES=48/CS_RES=${CS_RES}/" runConfig.sh
sed -i "s/NUM_CORES_PER_NODE=48/NUM_CORES_PER_NODE=${NUM_CORES_PER_NODE}/" runConfig.sh
sed -i "s/nCores=6/nCores=${TOTAL_CORES}/" gchp.cloud.run

# execute scripts
chmod +x runConfig.sh
chmod +x gchp.cloud.run
chmod +x gchp
./runConfig.sh
echo "running gchp"
./gchp.cloud.run
echo "finished running gchp"
echo "uploading output dir"
aws s3 cp gchp.log "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/outputDir/gchp.log"
aws s3 cp HEMCO.log "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/outputDir/HEMCO.log"
aws s3 cp outputDir/ "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/outputDir" --recursive
echo "finished uploading output dir"

#TODO on exit code 0 throw an error
test $err = 0 # Return non-zero if any command failed
exit $err