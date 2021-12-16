#!/usr/bin/env bash
err=0
trap 'err=1' ERR
source /environments/gchp_source.env
REPO_PATH="/gc-src"

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
cd /home/default_rundir/build

# NOTE: doesn't work on m1 macbook air due to an issue with qemu
cmake ../CodeDir
cmake . -DRUNDIR=".."
make -j
make install
cd ..
echo "File added to prevent s3 auto deletion of empty OutputDir" > OutputDir/README.md
# check what time period to use -- default is 1Mon
if [[ "x${TIME_PERIOD}" == "x1Day" ]]; then
  echo "creating rundir for 1Day time period"
  sed -i "s/End   YYYYMMDD, hhmmss  : 20190801 000000/End   YYYYMMDD, hhmmss  : 20190702 000000/" input.geos
  sed -i "s/DiagnFreq:                   Monthly/DiagnFreq:                   End/" HEMCO_Config.rc
  sed -i "s/00000100 000000/'End'/g" HISTORY.rc
fi
echo "starting run directory upload"
aws s3 cp /home/default_rundir "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/rundir" --recursive --quiet
echo "Finished run directory upload"
test $err = 0 # Return non-zero if any command failed
exit $err