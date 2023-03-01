#########################################################################
# job.pyx - pyslurm slurmdbd job api
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# Pyslurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Pyslurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3
# cython: embedsignature=True


from pyslurm.core.error import RPCError
from pyslurm.core.common.ctime import date_to_timestamp
from pyslurm.core.common.uint import *

# Maybe prefix these classes with something like "DB" to avoid name collision
# with the other classes from pyslurm/core/job ?

cdef class JobStep:

    def __cinit__(self):
        self.ptr = NULL

    def __dealloc__(self):
        slurmdb_destroy_step_rec(self.ptr)
        self.ptr = NULL

    @staticmethod
    cdef JobStep from_ptr(slurmdb_step_rec_t *step):
        cdef JobStep wrap = JobStep.__new__(JobStep)
        wrap.ptr = step
        return wrap

    def _xlate_from_id(self, sid):
        if sid == slurm.SLURM_BATCH_SCRIPT:
            return "batch"
        elif sid == slurm.SLURM_EXTERN_CONT:
            return "extern"
        elif sid == slurm.SLURM_INTERACTIVE_STEP:
            return "interactive"
        elif sid == slurm.SLURM_PENDING_STEP:
            return "pending"
        else:
            return sid

    def _xlate_to_id(self, sid):
        if sid == "batch":
            return slurm.SLURM_BATCH_SCRIPT
        elif sid == "extern":
            return slurm.SLURM_EXTERN_CONT
        elif sid == "interactive":
            return slurm.SLURM_INTERACTIVE_STEP
        elif sid == "pending":
            return slurm.SLURM_PENDING_STEP
        else:
            return int(sid)

    @property
    def id(self):
        return self._xlate_from_id(self.ptr.step_id.step_id)

    @property
    def job_id(self):
        return self.ptr.step_id.job_id

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.stepname)


cdef class JobConditions:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_job_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_job_cond_t*>try_xmalloc(sizeof(slurmdb_job_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_job_cond_t")
        
        self.ptr.db_flags = slurm.SLURMDB_JOB_FLAG_NOTSET
        self.ptr.flags |= slurm.JOBCOND_FLAG_NO_TRUNC

    def _create_job_cond(self):
        self._alloc()
        cdef slurmdb_job_cond_t *ptr = self.ptr

        ptr.usage_start = date_to_timestamp(self.start_time)  
        ptr.usage_end = date_to_timestamp(self.end_time)  
        slurmdb_job_cond_def_start_end(ptr)
        SlurmList.to_char_list(&ptr.acct_list, self.accounts)
        SlurmList.to_char_list(&ptr.associd_list, self.association_ids)
        SlurmList.to_char_list(&ptr.cluster_list, self.clusters)
        SlurmList.to_char_list(&ptr.constraint_list, self.constraints)


cdef class Jobs(dict):

    def __init__(self, *args, **kwargs):
        cdef:
            Job job
            JobStep step
            Connection db_conn
            JobConditions job_cond
            SlurmListItem job_ptr
            SlurmListItem step_ptr
            SlurmList step_list

        # Allow the user to both specify search conditions via a JobConditions
        # instance or **kwargs.
        if args and isinstance(args[0], JobConditions):
            job_cond = <JobConditions>args[0]
        else:
            job_cond = JobConditions(**kwargs)

        job_cond._create_job_cond()
        # TODO: Have a single, global DB connection in pyslurm internally?
        db_conn = Connection()
        self.info = SlurmList.wrap(slurmdb_jobs_get(db_conn.conn,
                                                    job_cond.ptr))
        if self.info.is_null():
            raise RPCError(msg="Failed to get Jobs from slurmdbd")

        # TODO: For multi-cluster support, remove duplicate federation jobs
        for job_ptr in SlurmList.iter_and_pop(self.info):
            job = Job.from_ptr(<slurmdb_job_rec_t*>job_ptr.data)
            self[job.id] = job

            step_list = SlurmList.wrap(job.ptr.steps, owned=False) 
            for step_ptr in SlurmList.iter_and_pop(step_list):
                step = JobStep.from_ptr(<slurmdb_step_rec_t*>step_ptr.data)
                job.steps[step.id] = step

        
cdef class Job:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, int job_id):
        pass

    def __dealloc__(self):
        slurmdb_destroy_job_rec(self.ptr)
        self.ptr = NULL

    @staticmethod
    cdef Job from_ptr(slurmdb_job_rec_t *in_ptr):
        cdef Job wrap = Job.__new__(Job)
        wrap.ptr = in_ptr
        wrap.steps = JobSteps.__new__(JobSteps)
        return wrap

    @property
    def account(self):
        return cstr.to_unicode(self.ptr.account)

    @property
    def id(self):
        return self.ptr.jobid
