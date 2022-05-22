#!/usr/bin/env bash
set -x
pkg_dir="packages/python"

echo "Installing python dependencies to ${pkg_dir}"
mkdir -p ${pkg_dir}
python3.9 -m pip install -r requirements.txt --target ${pkg_dir}
