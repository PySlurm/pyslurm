#!/bin/bash

VERSION=$(grep "Version:.*[0-9]" pyslurm.spec | tr -s " " |  awk '{print $2;}')
RELEASE=$(grep "%global.*rel.*[-1-9]" pyslurm.spec | tr -s " " | awk '{print $3}')

echo $VERSION
echo $RELEASE

if [ "${RELEASE}" -gt 1 ]; then
    SUFFIX=${VERSION}-${RELEASE}
else
    SUFFIX=${VERSION}
fi

GITTAG=$(git log --format=%ct.%h -1)

mkdir -p BUILD SOURCES SPECS RPMS BUILDROOT
git archive --format=tar.gz -o "SOURCES/pyslurm-${SUFFIX}.tar.gz" --prefix="pyslurm-${SUFFIX}/" HEAD
cp pyslurm.spec "SPECS"
rpmbuild --define "gittag ${GITTAG}" --define "_topdir $PWD" -ba SPECS/pyslurm.spec

