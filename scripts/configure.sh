#!/bin/bash
set -e

######################################################
# Configure Slurm for testing, after building PySlurm
######################################################

# Add fake licenses for testing
echo "---> Adding licenses"
echo "Licenses=fluent:30,ansys:100,matlab:50" >> /etc/slurm/slurm.conf

# Add fake topology for testing
echo "---> Adding topology"
cat > /etc/slurm/topology.conf << EOF
SwitchName=s0 Nodes=c[0-5]
SwitchName=s1 Nodes=c[6-10]
SwitchName=s2 Switches=s[0-1]
EOF

# Configure topology plugin
echo "---> Configuring topology plugin"
echo 'TopologyPlugin=topology/tree' >> /etc/slurm/slurm.conf

# Wait for database process to start
MAX_WAIT_DB=30
until 2>/dev/null > /dev/tcp/0.0.0.0/6819 || [ $MAX_WAIT_DB -lt 1 ]
do
    echo "---> Waiting for Slurmdbd (retries left $MAX_WAIT_DB)"
    sleep 1
    MAX_WAIT_DB=$((MAX_WAIT_DB - 1))
done

# Add the cluster to the slurm database
sacctmgr --immediate add cluster name=linux

# Restart Slurm components to apply configuration changes
supervisorctl restart slurmctld
supervisorctl restart slurmd


####################################################
# Get some output for debugging and troubleshooting
####################################################

# Wait for nodes to become IDLE
MAX_WAIT_IDLE=30
until sinfo | grep -q normal.*idle || [ $MAX_WAIT_IDLE -lt 1 ]
do
    echo "---> Waiting for nodes to transition to IDLE (retries left $MAX_WAIT_IDLE)"
    sleep 1
    MAX_WAIT_IDLE=$((MAX_WAIT_IDLE - 1))
done

# Print the PySlurm version
echo "---> PySlurm version"
python$PYTHON -c "import pyslurm; print(pyslurm.version())"

# Print the Slurm API version
echo "---> Slurm API version"
python$PYTHON -c "import pyslurm; print(pyslurm.slurm_api_version())"

# Submit test job with jobstep via srun for testing
echo "---> Submitting sleep job"
sbatch --wrap="srun sleep 1000"

# Wait for the job to transition from PENDING to RUNNING
MAX_WAIT_RUNNING=30
until scontrol show job | grep JobState=RUNNING || [ $MAX_WAIT_RUNNING -lt 1 ]
do
    echo "---> Waiting for job to transition to RUNNING (retries left $MAX_WAIT_RUNNING)"
    sleep 1
    MAX_WAIT_RUNNING=$((MAX_WAIT_RUNNING - 1))
done

# Show jobs
squeue

# Show cluster
sacctmgr list cluster

# Get output from various scontrol show commands
echo "---> scontrol -d show job"
scontrol -d show job
echo "---> scontrol -d show node c1"
scontrol -d show node c1
echo "---> scontrol -d show partition"
scontrol -d show partition
echo "---> scontrol -d show license"
scontrol -d show license
echo "---> scontrol -d show steps"
scontrol -d show steps
echo "---> scontrol -d show topology"
scontrol -d show topology
