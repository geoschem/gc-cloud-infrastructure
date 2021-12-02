#!/usr/bin/env bash
# setup environment
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
./gcclassic | tee gcclasic.log
echo "finished running gcclassic"
echo "uploading output dir"
aws s3 cp gcclassic.log "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/outputDir/gcclassic.log"
aws s3 cp HEMCO.log "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/outputDir/HEMCO.log"
aws s3 cp outputDir/ "${S3_RUNDIR_PATH}${TAG_NAME}/gcc/outputDir" --recursive
echo "finished uploading output dir"
