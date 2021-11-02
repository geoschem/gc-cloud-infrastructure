#!/usr/bin/env bash
export SPACK_ROOT="/opt/spack"
source /gchp_source.env
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
mkdir /gc-src/build
cd /gc-src/build
# NOTE: doesn't work on m1 macbook air due to an issue with qemu
cmake /gc-src
cmake . -DRUNDIR="../../home/gc_default_rundir"
make -j
make -j install
echo "starting run directory upload"
aws s3 cp /home/gc_default_rundir $S3_RUNDIR_PATH --recursive --quiet
echo "Finished run directory upload"