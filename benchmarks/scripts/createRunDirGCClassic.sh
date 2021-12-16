#!/usr/bin/env bash
err=0
trap 'err=1' ERR
source /environments/gchp_source.env
REPO_PATH="/gc-src"
RUNDIR="/home/default_rundir"

# clone and checkout the specified version
/scripts/utils/get-repo.sh GCC $REPO_PATH

mkdir /home/ExtData
cd "$REPO_PATH/run"
cat << 'EOF' > run_input.txt
/home/ExtData
1
2
1
1
1
/home
default_rundir
n
EOF
cat "run_input.txt" | ./createRunDir.sh
cd "$RUNDIR/build"

# NOTE: doesn't work on m1 macbook air due to an issue with qemu
cmake ../CodeDir
cmake . -DRUNDIR=".."
make -j
make install

# configure simulation settings
/scripts/utils/set-config.sh GCC $RUNDIR

echo "starting run directory upload"
aws s3 cp $RUNDIR "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/rundir" --recursive --quiet
echo "Finished run directory upload"
test $err = 0 # Return non-zero if any command failed
exit $err
