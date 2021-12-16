#!/usr/bin/env bash
# setup environment
err=0
trap 'err=1' ERR
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
# fetch the created/compiled run directory
echo "downloading run directory from s3"
aws s3 cp "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/rundir" /home/default_rundir --recursive --quiet
echo "finished downloading run directory from s3"
# get input data
cd /home/default_rundir
chmod +x gcclassic
chmod +x download_data.py
echo "downloading input data"
./gcclassic --dryrun | tee log.dryrun
./download_data.py log.dryrun aws
echo "finished downloading input data"
# create a symlinks
ln -s /gc-src/ CodeDir

# execute scripts
echo "running gcclassic"
./gcclassic | tee gcclassic.log
echo "finished running gcclassic"
echo "uploading output dir"
aws s3 cp gcclassic.log "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/OutputDir/gcclassic.log"
aws s3 cp HEMCO.log "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/OutputDir/HEMCO.log"
aws s3 cp OutputDir/ "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/OutputDir" --recursive
echo "finished uploading output dir"
test $err = 0 # Return non-zero if any command failed
exit $err
