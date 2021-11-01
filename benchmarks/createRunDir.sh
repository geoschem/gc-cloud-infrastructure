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
cmake /gc-src
cmake . -DRUNDIR="../../gc_default_rundir"
make -j
make -j install
