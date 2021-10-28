#!/usr/bin/env bash
. /init.rc
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
./createRunDir.sh 