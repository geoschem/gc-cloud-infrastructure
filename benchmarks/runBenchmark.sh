#!/usr/bin/env bash
# setup environment
source /gchp_source.env
mkdir /home/ExtData

# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp $S3_RUNDIR_PATH/rundir /home/gc_default_rundir --recursive --quiet
echo "finished downloading run directory from s3"

cd /home/gc_default_rundir

# configure runConfig
sed -i "s/TOTAL_CORES=96/TOTAL_CORES=6/" runConfig.sh
sed -i "s/NUM_NODES=2/NUM_NODES=1/" runConfig.sh
sed -i "s/CS_RES=48/CS_RES=24/" runConfig.sh
sed -i "s/NUM_CORES_PER_NODE=48/NUM_CORES_PER_NODE=6/" runConfig.sh

# TODO use bash data catalog to download ExtData 
touch initial_GEOSChem_rst.c24_fullchem.nc

# TODO figure out why binary isn't copied to rundir
cp build/bin/gchp gchp

# execute scripts
chmod +x runConfig.sh
chmod +x gchp
./runConfig.sh
echo "running gchp"
./gchp
echo "finished running gchp"