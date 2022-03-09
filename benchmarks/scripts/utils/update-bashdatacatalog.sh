#!/usr/bin/env bash

# clone data catalogs
echo "cloning the input data catalogs"
git clone https://github.com/geoschem/input-data-catalogs.git
cd input-data-catalogs 
git submodule update --init --recursive

# update the bashdatacatalog branch
echo "pulling the branch"
cd /opt/bashdatacatalog
git pull

# add to path
export PATH="/opt/bashdatacatalog/bin:$PATH"

# run bashdatacatalog commands
echo "fetching bashdatacatalog metadata"
cd /ExtData
bashdatacatalog-fetch input-data-catalogs/develop/EmissionsInputs.csv /input-data-catalogs/develop/ChemistryInputs.csv /input-data-catalogs/MeteorologicalInputs.csv

echo "downloading data"
bashdatacatalog-list -am -f xargs-curl -r 2019-06-30,2019-08-01 input-data-catalogs/develop/EmissionsInputs.csv /input-data-catalogs/develop/ChemistryInputs.csv /input-data-catalogs/MeteorologicalInputs.csv | xargs curl

echo "remove unnecessary input data"
bashdatacatalog-list -au -f xargs-rm -r 2019-06-30,2019-08-01 input-data-catalogs/develop/EmissionsInputs.csv /input-data-catalogs/develop/ChemistryInputs.csv /input-data-catalogs/MeteorologicalInputs.csv | xargs rm
echo "finished updating input data"

echo "temporary fix for downloading missing files"
bashdatacatalog-list -t -f xargs-curl -p 'multiyearice.merra2.05x0625.2017.nc\|NO-em-anthro_CMIP_CEDS_2010.nc' input-data-catalogs/develop/EmissionsInputs.csv | xargs curl
echo "finished updating data"
