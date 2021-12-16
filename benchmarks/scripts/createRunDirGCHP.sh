#!/usr/bin/env bash
err=0
trap 'err=1' ERR
source /environments/gchp_source.env
REPO_PATH="/gc-src"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCHP $REPO_PATH

mkdir /home/ExtData
cd "$REPO_PATH/run"
cat << 'EOF' > run_input.txt
/home/ExtData
1
2
1
/home
default_rundir
n
EOF
cat "run_input.txt" | ./createRunDir.sh
mkdir /home/default_rundir/build
cd /home/default_rundir/build

# NOTE: doesn't work on m1 macbook air due to an issue with qemu
cmake ../CodeDir
cmake . -DRUNDIR=".."
make -j
make -j install

# configure runConfig
cd ..
sed -i "s/TOTAL_CORES=96/TOTAL_CORES=${TOTAL_CORES}/" runConfig.sh
sed -i "s/NUM_NODES=2/NUM_NODES=${NUM_NODES}/" runConfig.sh
sed -i "s/CS_RES=48/CS_RES=${CS_RES}/" runConfig.sh
sed -i "s/NUM_CORES_PER_NODE=48/NUM_CORES_PER_NODE=${NUM_CORES_PER_NODE}/" runConfig.sh

# check what time period to use -- default is 1Mon
if [[ "x${TIME_PERIOD}" == "x1Day" ]]; then
  echo "creating rundir for 1Day time period"
  sed -i 's/End_Time="20190801 000000"/"End_Time=20190702 000000"/' runConfig.sh
  sed -i 's/Duration="00000100 000000"/Duration="00000001 000000"/' runConfig.sh
fi

echo "File added to prevent s3 auto deletion of empty OutputDir" > OutputDir/README.md

echo "starting run directory upload"
aws s3 cp /home/default_rundir "${S3_RUNDIR_PATH}${TAG_NAME}/gchp/rundir" --recursive --quiet
echo "Finished run directory upload"
test $err = 0 # Return non-zero if any command failed
exit $err