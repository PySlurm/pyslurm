#!/bin/bash
set -e

#
# Configure Slurm with extras for testing, after building PySlurm.
#

# Add fake licenses for testing
echo 'Licenses=fluent:30,ansys:100,matlab:50' >> /etc/slurm/slurm.conf

# Add fake topology for testing
cat > /etc/slurm/topology.conf << EOF
SwitchName=s0 Nodes=c[0-5]
SwitchName=s1 Nodes=c[6-10]
SwitchName=s2 Switches=s[0-1]
EOF

# Configure topology plugin
echo 'TopologyPlugin=topology/tree' >> /etc/slurm/slurm.conf

# Add a delay to give time for database process to start
sleep 10

# Add the cluster to the slurm database
sacctmgr --immediate add cluster name=linux

# Restart Slurm components to apply configuration changes
supervisorctl restart slurmctld
supervisorctl restart slurmd
