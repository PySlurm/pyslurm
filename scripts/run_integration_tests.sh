#!/bin/bash
set -e

CONTAINER_NAME="${CONTAINER_NAME:-slurmctl}"
VENV_PATH="/opt/pyslurm-venv"
BUILD_JOBS="${PYSLURM_BUILD_JOBS:-4}"

usage() {
    echo "Usage: $0 [-c container_name] [-j build_jobs] [-s]"
    echo "  -c  Container name (default: slurmctl)"
    echo "  -j  Parallel build jobs (default: 4)"
    echo "  -s  Skip build step (reuse existing install)"
    exit 1
}

SKIP_BUILD=false

while getopts ":c:j:sh" o; do
    case "${o}" in
        c) CONTAINER_NAME="${OPTARG}" ;;
        j) BUILD_JOBS="${OPTARG}" ;;
        s) SKIP_BUILD=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check that the container is running
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

# Wait for compute nodes to register and become idle
echo "Waiting for compute nodes..."
for i in $(seq 1 30); do
    node_info=$(docker exec "$CONTAINER_NAME" sinfo -h -o "%T %D" 2>/dev/null)
    if echo "$node_info" | grep -q "idle"; then
        idle_count=$(echo "$node_info" | awk '/idle/{print $2}')
        echo "Compute nodes ready ($idle_count idle)."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "Error: Compute nodes did not become ready in time."
        docker exec "$CONTAINER_NAME" sinfo
        exit 1
    fi
    sleep 2
done

if [ "$SKIP_BUILD" = false ]; then
    echo "Building and installing PySlurm..."
    docker exec "$CONTAINER_NAME" bash -c "
        python3 -m venv $VENV_PATH 2>/dev/null || true
        source $VENV_PATH/bin/activate
        pip install -q -r /pyslurm/test_requirements.txt
        cd /pyslurm
        python setup.py build -j$BUILD_JOBS
        python setup.py install
    "
fi

echo "Running integration tests..."
docker exec "$CONTAINER_NAME" bash -c "
    source $VENV_PATH/bin/activate
    cd /pyslurm
    pytest tests/integration -v \"\$@\"
" -- "$@"
