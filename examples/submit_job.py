#!/usr/bin/env python

import pyslurm

rc = pyslurm.slurm_submit_batch_job({'wrap':'hostname'})
rc = pyslurm.slurm_submit_batch_job({'script':'test.sh', 'mem':4096, 'mincpus':4})
