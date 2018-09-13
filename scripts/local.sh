#!/bin/bash
export SLURM=17.02.10
export CYTHON=0.27.3
export CENTOS=7
export PYTHON=2.7

docker run -d -it -h ernie \
    -v ${PWD}:/pyslurm:Z \
    --name slurm-${SLURM} \
    giovtorres/docker-centos${CENTOS}-slurm:${SLURM}

docker exec -e PYTHON=${PYTHON} -e CYTHON=${CYTHON} slurm-${SLURM} /pyslurm/scripts/build.sh
docker exec -e PYTHON=${PYTHON} -e CYTHON=${CYTHON} slurm-${SLURM} /pyslurm/scripts/configure.sh
docker exec -e PYTHON=${PYTHON} -e CYTHON=${CYTHON} slurm-${SLURM} /pyslurm/scripts/run_tests.sh
docker rm -f slurm-${SLURM}

unset SLURM
unset CYTHON
unset CENTOS
unset PYTHON
