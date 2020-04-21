# Build PySlurm (20.02.1)

## Checkout PySlurm

```bash
cd /root
git clone https://github.com/bikerdanny/pyslurm.git
cd pyslurm
git checkout 20.02.1
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
