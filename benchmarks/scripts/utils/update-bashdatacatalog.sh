#!/usr/bin/env bash

# clone data catalogs
echo "cloning the input data catalogs"
git clone https://github.com/geoschem/input-data-catalogs.git
cd input-data-catalogs 
git submodule update --init --recursive

# checkout the correct branch
echo "checking out interface2 branch"
cd /opt/bashdatacatalog
git fetch
git checkout feature/interface2
export PATH="/opt/bashdatacatalog/bin:$PATH"

# run bashdatacatalog commands
echo "fetching bashdatacatalog metadata"
cd /ExtData
bashdatacatalog-fetch input-data-catalogs/develop/*.csv /input-data-catalogs/develop/*.csv /input-data-catalogs/MeteorologicalInputs.csv

echo "downloading data"
bashdatacatalog-list -am -f xargs-curl -r 2018-12-31 2020-01-01 /input-data-catalogs/develop/*.csv /input-data-catalogs/MeteorologicalInputs.csv | xargs curl

echo "remove unnecessary input data"
bashdatacatalog-list -au -f xargs-rm -r 2018-12-31 2020-01-01 /input-data-catalogs/MeteorologicalInputs.csv /input-data-catalogs/develop/*.csv | xargs rm
echo "finished updating input data"