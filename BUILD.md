# Build PySlurm (20.11.2)

## Prepare Slurm container (optional)

```bash
git clone https://github.com/bikerdanny/docker-centos-slurm
cd docker-centos-slurm
pip3 install j2cli
j2 Dockerfile.j2 config.ini > Dockerfile
docker build -t bikerdanny/slurm:20.02.5 .
sed -i "s/controller1/c10/g" config.ini
sed -i "s/compute1/c10/g" config.ini
j2 aio.docker-compose.yml.j2 config.ini > docker-compose.yml
mkdir var_lib_mysql
mkdir etc_munge
mkdir etc_slurm
mkdir shared
docker-compose up -d
docker-compose exec c10 bash
supervisorctl stop slurmctld
echo "SwitchName=s2 Nodes=c10" > /etc/slurm/topology.conf
echo "#
# TOPOLOGY
TopologyPlugin=topology/tree
#
# PlugStackConfig
PlugStackConfig=/etc/slurm/plugstack.conf" >> /etc/slurm/slurm.conf
sacctmgr show cluster # if the command returns successfully, you can start slurmctld again
supervisorctl start slurmctld
sinfo
```
The following steps you could do inside the container.

## Checkout PySlurm

```bash
cd /root
git clone https://github.com/bikerdanny/pyslurm.git
cd pyslurm
git checkout 20.02.5
```

## Build pxd files for slurm.h slurmdb.h and slurm_errno.h

```bash
pip3 install autopxd2
cd /usr/include
autopxd --include-dir /usr/include slurm/slurm.h /root/pyslurm/pyslurm/slurm.h.pxd
autopxd --include-dir /usr/include slurm/slurmdb.h /root/pyslurm/pyslurm/slurmdb.h.pxd
autopxd --include-dir /usr/include slurm/slurm_errno.h /root/pyslurm/pyslurm/slurm_errno.h.pxd
```

## Patch and modify pxd files

```bash
cd /root/pyslurm/pyslurm
patch -p0 < slurm.h.pxd.patch
patch -p0 < slurmdb.h.pxd.patch
sed -i "s/slurm_addr_t control_addr/#slurm_addr_t control_addr/g" slurmdb.h.pxd
sed -i "s/pthread_mutex_t lock/#pthread_mutex_t lock/g" slurmdb.h.pxd
patch -p0 < slurm_errno.h.pxd.patch
```

## Create slurm.pxd from template slurm.j2

```bash
cd /root/pyslurm/pyslurm
pip3 install j2cli
j2 slurm.j2 > slurm.pxd
```

## Build and install PySlurm

```bash
pip3 install Cython
cd /root/pyslurm
python3 setup.py build
python3 setup.py install
```

## Test PySlurm

```bash
pip3 install nose
cd /root
python3 $(which nosetests) -v pyslurm/tests
```
