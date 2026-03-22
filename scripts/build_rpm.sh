#!/bin/bash
set -e

CONTAINER_NAME="${CONTAINER_NAME:-slurmctl}"
RPMBUILD_DIR="/root/rpmbuild"

usage() {
    echo "Usage: $0 [-c container_name]"
    echo "  -c  Container name (default: slurmctl)"
    exit 1
}

while getopts ":c:h" o; do
    case "${o}" in
        c) CONTAINER_NAME="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if ! docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" &>/dev/null; then
    echo "Error: Container '$CONTAINER_NAME' is not running."
    echo "Start it with: docker compose up -d"
    exit 1
fi

# Wait for slurmctld to be ready
echo "Waiting for Slurm controller..."
for i in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" scontrol ping 2>/dev/null | grep -q "UP"; then
        echo "Slurm controller is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "Error: Slurm controller did not become ready in time."
        exit 1
    fi
    sleep 2
done

echo "Installing RPM build dependencies in container '$CONTAINER_NAME'..."
docker exec "$CONTAINER_NAME" bash -c "
    set -e
    dnf install -y -q rpm-build python3-devel pyproject-rpm-macros \
        python3-Cython python3-setuptools python3-wheel
"

# Build sdist if not already present (may have been built by a prior CI step)
if ls dist/*.tar.gz &>/dev/null; then
    echo "Using existing sdist in dist/"
else
    echo "Building sdist..."
    docker exec "$CONTAINER_NAME" bash -c "
        set -e
        pip install -q build
        cd /pyslurm
        python -m build --sdist
    "
fi

echo "Building RPM..."
docker exec "$CONTAINER_NAME" bash -c "
    set -e
    mkdir -p ${RPMBUILD_DIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    cp /pyslurm/dist/*.tar.gz ${RPMBUILD_DIR}/SOURCES/
    cp /pyslurm/pyslurm.spec ${RPMBUILD_DIR}/SPECS/
    rpmbuild -ba ${RPMBUILD_DIR}/SPECS/pyslurm.spec
"

echo "Installing RPM in container '$CONTAINER_NAME'..."
docker exec "$CONTAINER_NAME" bash -c "
    set -e
    if rpm -q python3-pyslurm &>/dev/null; then
        dnf reinstall -y -q ${RPMBUILD_DIR}/RPMS/*/python3-pyslurm-*.rpm
    else
        dnf install -y -q ${RPMBUILD_DIR}/RPMS/*/python3-pyslurm-*.rpm
    fi
"

docker exec -i -w /tmp "$CONTAINER_NAME" python3 - << 'PYEOF'
import pyslurm
print("pyslurm version:", pyslurm.__version__)
from pyslurm import slurmctld
import pprint
conf = slurmctld.Config.load()
pprint.pprint(conf.to_dict())
PYEOF

echo "RPM build and install successful."
