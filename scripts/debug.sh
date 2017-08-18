#!/bin/bash
set -e

#
# Get some output for debugging and troubleshooting.
#

# Sleep for a few seconds to wait for nodes to become idle
sleep 10

# Print the PySlurm version
python$PYTHON -c "import pyslurm; print(pyslurm.version())"

# Print the Slurm API version
python$PYTHON -c "import pyslurm; print(pyslurm.slurm_api_version())"

docker exec slurm-$SLURM sbatch --wrap="srun sleep 1000"
  - sleep 10
  - docker exec slurm-$SLURM scontrol -d show job
  - docker exec slurm-$SLURM scontrol -d show node c1
  - docker exec slurm-$SLURM scontrol -d show partition
  - docker exec slurm-$SLURM scontrol -d show license
  - docker exec slurm-$SLURM scontrol -d show steps
  - docker exec slurm-$SLURM scontrol -d show topology

# Submit test job with jobstep via srun for testing
sbatch --wrap="srun sleep 1000"

# Sleep for a few seconds to wait for the job to transition
# from PENDING to RUNNING
sleep 10

# Get output from various scontrol show commands
scontrol -d show job
scontrol -d show node c1
scontrol -d show partition
scontrol -d show license
scontrol -d show steps
scontrol -d show topology
