#!/usr/bin/env bash

# Description: Download necessary input data for the given simulation type
#
# Usage:
#   ./get-repo.sh <simulation-type> <data-path>
#       simulation-type: either GCC or GCHP. Determines which git repo to clone
#       data-path: (only GCHP) path to download the data to (eg. /home/ExtData)

echo "downloading input data for $1"
# GCHP Download
if [[ "x$1" == "xGCHP" ]]; then
  echo "running bashdatacatalog"
  cd $2
  mkdir catalogs
  cd catalogs
  # TODO replace hardcoded path
  wget -r -nH --cut-dirs=3 -np -A "*.csv" "geoschemdata.wustl.edu/ExtData/DataCatalogs/${DATA_CATALOG_VERSION}/"
  rm InitialConditions.csv # don't download restarts -- too big
  cd ..
  bashdatacatalog catalogs/*.csv fetch
  if [[ "x${GEOSCHEM_BENCHMARK_TIME_PERIOD}" == "x1Day" ]]; then
    echo "downloading data for 1Day time period"
    bashdatacatalog catalogs/*.csv list-missing relative 2019-06-30 2019-07-02 \
    | sed "s#./\(.*\)#aws s3 cp s3://gcgrid/\1 $2/\home/ExtData/\1 --request-payer#g" \
    | bash
  else
    echo "downloading data for 1Mon time period"
    bashdatacatalog catalogs/*.csv list-missing relative 2019-06-30 2019-08-01 \
    | sed "s#./\(.*\)#aws s3 cp s3://gcgrid/\1 $2/\home/ExtData/\1 --request-payer#g" \
    | bash
  fi

# GCC Download
elif [[ "x$1" == "xGCC" ]]; then
  echo "downloading input data for $1"
  chmod +x gcclassic
  chmod +x download_data.py
  ./gcclassic --dryrun | tee log.dryrun
  ./download_data.py log.dryrun aws
else
  echo "ERROR: Invalid parameter for simulation type given: $1"
  exit 1
fi
echo "finished downloading input data for $1"
