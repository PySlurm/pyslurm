rm -Rf ./build/ ./pyslurm/pyslurm.c ./pyslurm/__init__.pyc
python setup.py build
#gcc -pthread -shared build/temp.linux-x86_64-2.4/pyslurm/pyslurm.o -L /opt/lib/ -lslurm /opt/lib/slurm/auth_none.so -o build/lib.linux-x86_64-2.4/pyslurm/pyslurm.so
#python setup.py install
export PYTHONPATH=/home/sgorget/pyslurm/build/lib.linux-x86_64-2.6/
(
	cd /tmp
	python -c "import pyslurm; print dir(pyslurm)"
	python -c "import pyslurm;a, b =pyslurm.slurm_load_partitions();print pyslurm.slurm_print_partition_info_msg(b)"
)
