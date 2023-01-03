#!/bin/bash
set -e

usage() { echo "Usage: $0 [-j jobs]" 1>&2; exit 1; }

# Option to allow parallel build
OPT_JOBS=1

PYTHON_VERSION=3

while getopts ":j:" o; do
    case "${o}" in
        j)
            OPT_JOBS=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

python"$PYTHON_VERSION" setup.py build -j "$OPT_JOBS"
python"$PYTHON_VERSION" setup.py install
