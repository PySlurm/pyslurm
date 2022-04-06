# Global Environment
cdef extern char **environ

#
# Slurm Memory routines
#

cdef extern void slurm_xfree (void **)
cdef extern void *slurm_xcalloc(size_t, size_t, bool, bool, const char *, int, const char *)

cdef inline xfree(void **item):
    slurm_xfree(item)

cdef inline void *xmalloc(size_t size):
    return slurm_xcalloc(1, size, True, False, __FILE__, __LINE__, __FUNCTION__)

cdef inline void *try_xmalloc(size_t size):
    return slurm_xcalloc(1, size, True, True, __FILE__, __LINE__, __FUNCTION__)

cdef inline void xfree_ptr(void *ptr):
    slurm_xfree(&ptr)

#
# Slurm xstring functions
#

cdef extern char *slurm_xstrdup(const char *str)


#
# Slurm time functions
#


cdef extern void slurm_secs2time_str(time_t time, char *string, int size)
cdef extern void slurm_mins2time_str(time_t time, char *string, int size)
cdef extern int slurm_time_str2mins(const char *string)
cdef extern int slurm_time_str2secs(const char *string)
cdef extern void slurm_make_time_str(time_t *time, char *string, int size)
cdef extern time_t slurm_parse_time(char *time_str, int past)

#
# Slurm Job functions
#


cdef extern void slurm_free_job_desc_msg(job_desc_msg_t *msg)
cdef extern void slurm_free_job_info(job_info_t *job)
cdef extern void slurm_free_job_info_members(job_info_t *job)
cdef extern void slurm_free_job_step_info_response_msg(job_step_info_response_msg_t *msg)
cdef extern void slurm_free_job_step_info_members(job_step_info_t *msg)
cdef extern char *slurm_job_state_string(uint16_t inx)
cdef extern char *slurm_job_reason_string(int inx)
cdef extern char *slurm_job_share_string(uint16_t shared)

#
# Slurm environment functions
#

cdef extern void slurm_env_array_merge(char ***dest_array, const char **src_array)
cdef extern char **slurm_env_array_create()
cdef extern int slurm_env_array_overwrite(char ***array_ptr, const char *name, const char *value)
cdef extern void slurm_env_array_free(char **env_array)
# cdef extern void slurm_env_array_merge_slurm(char ***dest_array, const char **src_array)


cdef extern int slurm_select_fini()
