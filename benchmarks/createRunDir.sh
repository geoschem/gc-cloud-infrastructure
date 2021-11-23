#!/usr/bin/env bash
source /gchp_source.env
# checkout the specified version if given
if [[ -z "${TAG_NAME}" ]]; then
  rm -rf /gc-src
  git clone https://github.com/geoschem/GCHP.git /gc-src
  cd /gc-src
  git checkout ${TAG_NAME}
  git submodule update --init --recursive
fi

mkdir /home/ExtData
cd /gc-src/run
cat << 'EOF' > run_input.txt
/home/ExtData
1
2
1
/home
gc_default_rundir
n
EOF
cat "run_input.txt" | ./createRunDir.sh
mkdir /home/gc_default_rundir/build
cd /home/gc_default_rundir/build

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

echo "starting run directory upload"
aws s3 cp /home/gc_default_rundir "${S3_RUNDIR_PATH}rundir" --recursive --quiet
echo "Finished run directory upload"