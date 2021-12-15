#!/usr/bin/env bash
cd /
source /environments/gchp_source.env

rm -rf /gc-src
git clone https://github.com/geoschem/GCClassic.git /gc-src
cd /gc-src

# if supplied checkout the relevant tag
if [[ ! -z "${TAG_NAME}" ]]; then
  git checkout ${TAG_NAME}
fi

git submodule update --init --recursive

mkdir /home/ExtData
cd /gc-src/run
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

# check what time period to use -- default is 1Mon
if [[ "x${TIME_PERIOD}" == "x1Day" ]]; then
  echo "creating rundir for 1Day time period"
  sed -i "s/End   YYYYMMDD, hhmmss  : {DATE2} {TIME2}/End   YYYYMMDD, hhmmss  : 20190801 000000/" input.geos
  sed -i "s/DiagnFreq:                   Monthly/DiagnFreq:                   End/" HEMCO_Config.rc
fi
echo "starting run directory upload"
aws s3 cp /home/default_rundir "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/rundir" --recursive --quiet
echo "Finished run directory upload"