#!/usr/bin/env bash
# Description: This script is designed for automated benchmarking on aws 
# within a docker container deployed by aws batch. It will download a given 
# version of GCHP, create and compile a run directory with the specified 
# configuration, and upload the run directory to s3. 
report() {
  err=1
  echo -n "error at line ${BASH_LINENO[0]}, in call to "
  sed -n ${BASH_LINENO[0]}p $0
} >&2

err=0
trap report ERR
source /environments/gchp_source.env

# set default paths
REPO_PATH="/gc-src"
RUNDIR="/home/default_rundir"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCHP $REPO_PATH

mkdir /home/ExtData
cd "$REPO_PATH/run"

# create run directory
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
mkdir "$RUNDIR/build"
cd "$RUNDIR/build"

# compile code
# NOTE: doesn't work on m1 macbook air due to an issue with qemu
cmake ../CodeDir
cmake . -DRUNDIR=".."
make -j
make -j install

# configure simulation settings
/scripts/utils/set-config.sh GCHP $RUNDIR
if [ $err -gt 0 ]; then  
  exit $err
fi

echo "starting run directory upload"
aws s3 cp $RUNDIR "${S3_RUNDIR_PATH}${TIME_PERIOD}/${TAG_NAME}/gchp/rundir" --recursive --only-show-errors
echo "Finished run directory upload"