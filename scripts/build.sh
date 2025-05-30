#!/bin/bash
set -e

usage() { echo "Usage: $0 [-j jobs] [-d]" 1>&2; exit 1; }

OPT_JOBS=${PYSLURM_BUILD_JOBS:-1}
OPT_DEV='false'

while getopts ":j:d" o; do
    case "${o}" in
        j)
            OPT_JOBS=${OPTARG}
            ;;
        d)
            OPT_DEV='true'
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

PY_VER=$(python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')")
echo "Building with ${OPT_JOBS} cores"
export PYSLURM_BUILD_JOBS="$OPT_JOBS"

if [[ $PY_VER == "3.6" ]]
then
    pip install -v .
elif ${OPT_DEV}
then
    pip install -v --no-build-isolation --config-settings="--build-option=build_ext -j${OPT_JOBS}" -e .
else
    pip install -v . --config-settings="--build-option=build_ext -j${OPT_JOBS}"
fi


