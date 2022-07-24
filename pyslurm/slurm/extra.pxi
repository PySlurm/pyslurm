# Global Environment
cdef extern char **environ

#
# Slurm Memory routines
#

cdef extern void slurm_xfree (void **)
cdef extern void *slurm_xcalloc(size_t, size_t, bool, bool, const char *, int, const char *)

cdef inline xfree(void *__p):
    slurm_xfree(<void**>&__p)

cdef inline void *xmalloc(size_t __sz):
    return slurm_xcalloc(1, __sz, True, False, __FILE__, __LINE__, __FUNCTION__)

cdef inline void *try_xmalloc(size_t __sz):
    return slurm_xcalloc(1, __sz, True, True, __FILE__, __LINE__, __FUNCTION__)

cdef inline void xfree_ptr(void *__p):
    slurm_xfree(<void**>&__p)

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

cdef extern void slurm_env_array_merge(char ***dest_array, const char **src_array)
cdef extern char **slurm_env_array_create()
cdef extern int slurm_env_array_overwrite(char ***array_ptr, const char *name, const char *value)
cdef extern void slurm_env_array_free(char **env_array)

#
# Misc
#

cdef extern char *slurm_preempt_mode_string (uint16_t preempt_mode)
cdef extern char *slurm_node_state_string (uint32_t inx)
cdef extern char *slurm_step_layout_type_name (task_dist_states_t task_dist)
cdef extern char *slurm_reservation_flags_string (reserve_info_t *resv_ptr)
cdef extern void slurm_free_stats_response_msg (stats_info_response_msg_t *msg)
cdef extern int slurm_addto_char_list_with_case(List char_list, char *names, bool lower_case_noralization)
cdef extern int slurm_addto_step_list(List step_list, char *names)
cdef extern int slurmdb_report_set_start_end_time(time_t *start, time_t *end)
cdef extern uint16_t slurm_get_track_wckey()
