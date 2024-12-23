#!/bin/bash

usage() { echo "Usage: $0 [-j jobs]" 1>&2; exit 1; }

OPT_JOBS=${PYSLURM_BUILD_JOBS:-1}

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

python setup.py clean
pip install -r doc_requirements.txt
scripts/build.sh -j${OPT_JOBS} -d
mkdocs build
