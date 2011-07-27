python setup.py build
gcc -pthread -shared build/temp.linux-x86_64-2.4/pyslurm/pyslurm.o -L /opt/lib/ -lslurm /opt/lib/slurm/auth_none.so -o build/lib.linux-x86_64-2.4/pyslurm/pyslurm.so
python setup.py install
