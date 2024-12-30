#!/usr/bin/env bash

usage() { echo "Usage: $0 -v version -p path-to-github-io-dir [-d] " 1>&2; exit 1; }

opt_version=""
opt_path_to_remote=""
opt_default='false'
script_dir=$(dirname -- "${BASH_SOURCE[0]}")
path_to_mkdocs_config="$(realpath -- "$script_dir";)/../mkdocs.yml"

while getopts ":v:p:d" o; do
    case "${o}" in
        v)
            opt_version=${OPTARG}
            ;;
        p)
            opt_path_to_remote=${OPTARG}
            ;;
        d)
            opt_default='true'
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [[ -z "${opt_version}" ]]
then
    echo "Error: -v is required"
    usage
fi

if [[ -z "${opt_path_to_remote}" ]]
then
    echo "Error: -p is required"
    usage
fi

cd "$opt_path_to_remote"

if ${opt_default}
then
    mike set-default -b main -F "$path_to_mkdocs_config" "$opt_version"
    exit 0
fi

mike deploy -b main -F "$path_to_mkdocs_config" "$opt_version"
