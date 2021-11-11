#!/bin/bash
set -e

# CMD - Command to run for up to 30 seconds
# MSG - Message to print while waiting for command to run
RESULT=""
wait_for_cmd() {
    CMD="$1"
    MSG="$2"
    MAX_WAIT=30
    until eval ${CMD} || [ $MAX_WAIT -lt 1 ]
    do
        echo "---> ${MSG} (retries left $MAX_WAIT)"
        sleep 1
        MAX_WAIT=$((MAX_WAIT - 1))
    done

    if [ $MAX_WAIT -eq 0 ]
    then
    RESULT=false
    fi
}

######################################################
# Configure Slurm for testing, after building PySlurm
######################################################

# Add fake licenses for testing
echo "---> Adding licenses"
echo "Licenses=fluent:30,ansys:100,matlab:50" >> /etc/slurm/slurm.conf

# Add fake topology for testing
echo "---> Adding topology"
cat > /etc/slurm/topology.conf << EOF
SwitchName=s0 Nodes=c[1-5]
SwitchName=s1 Nodes=c[6-10]
SwitchName=s2 Switches=s[0-1]
EOF

# Configure topology plugin
echo "---> Configuring topology plugin"
echo 'TopologyPlugin=topology/tree' >> /etc/slurm/slurm.conf

# Wait for database process to start
wait_for_cmd "2>/dev/null > /dev/tcp/0.0.0.0/6819" "Waiting for Slurmdbd"

if [ "$RESULT" = false ]
then
    supervisorctl restart mysqld
    supervisorctl restart slurmdbd
    supervisorctl status
fi

# Add the cluster to the slurm database
#sacctmgr --immediate add cluster name=linux

# Restart Slurm components to apply configuration changes
supervisorctl restart slurmctld
supervisorctl restart slurmd


####################################################
# Get some output for debugging and troubleshooting
####################################################

# Wait for nodes to become IDLE
wait_for_cmd "sinfo | grep -q normal.*idle" "Waiting for nodes to transition to IDLE"

# TODO: convert to setup method/fixture
# Submit test job with jobstep via srun for testing
echo "---> Submitting sleep job"
sbatch --wrap="srun sleep 1000"

# Wait for the job to transition from PENDING to RUNNING
wait_for_cmd "scontrol show job | grep -q JobState=RUNNING" "Waiting for job to transition to RUNNING"

# Show jobs
squeue

# Show cluster
sacctmgr list cluster

# Debug for CentOS 6 only
# CentOS 6 tends move a little slower
wait_for_cmd "scontrol show license | grep -q LicenseName=matlab" "Waiting for licenses"
wait_for_cmd "scontrol show topology | grep -q Switches" "Waiting for topology"

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
