ctypedef enum persist_conn_type_t:
    PERSIST_TYPE_NONE = 0
    PERSIST_TYPE_DBD
    PERSIST_TYPE_FED
    PERSIST_TYPE_HA_CTL
    PERSIST_TYPE_HA_DBD
    PERSIST_TYPE_ACCT_UPDATE

# https://github.com/SchedMD/slurm/blob/master/src/common/slurm_persist_conn.h
ctypedef struct persist_msg_t:
    void *conn
    void *data
    uint32_t data_size
    uint16_t msg_type

ctypedef int (*_slurm_persist_conn_t_callback_proc) (void *arg, persist_msg_t *msg, buf_t **out_buffer, uint32_t *uid)

ctypedef void (*_slurm_persist_conn_t_callback_fini)(void *arg)

ctypedef struct slurm_persist_conn_t:
    void *auth_cred
    _slurm_persist_conn_t_callback_proc callback_proc
    _slurm_persist_conn_t_callback_fini callback_fini
    char *cluster_name
    time_t comm_fail_time
    uint16_t my_port
    int fd
    uint16_t flags
    bool inited
    persist_conn_type_t persist_type
    uid_t r_uid
    char *rem_host
    uint16_t rem_port
    time_t *shutdown
    pthread_t thread_id
    int timeout
    slurm_trigger_callbacks_t trigger_callbacks;
    uint16_t version

# https://github.com/SchedMD/slurm/blob/master/src/common/pack.h#L68
ctypedef struct buf_t:
    uint32_t magic
    char *head
    uint32_t size
    uint32_t processed
    bool mmaped

# https://github.com/SchedMD/slurm/blob/master/src/common/slurm_protocol_defs.h
ctypedef struct return_code_msg_t:
    uint32_t return_code

ctypedef struct job_id_msg_t:
    uint32_t job_id
    uint16_t show_flags

ctypedef enum slurm_msg_type_t:
    REQUEST_SHARE_INFO    = 2022
    REQUEST_BATCH_SCRIPT  = 2051
    RESPONSE_BATCH_SCRIPT = 2052
    RESPONSE_SLURM_RC     = 8001

ctypedef struct forward_t:
    uint16_t cnt
    uint16_t init
    char *nodelist
    uint32_t timeout
    uint16_t tree_width

ctypedef struct forward_struct_t:
    char *buf
    int buf_len
    uint16_t fwd_cnt
    pthread_mutex_t forward_mutex
    pthread_cond_t notify
    List ret_list
    uint32_t timeout

ctypedef struct slurm_msg_t:
    slurm_addr_t address
    void *auth_cred
    int auth_index
    uid_t auth_uid
    bool auth_uid_set
    uid_t restrict_uid
    bool restrict_uid_set
    uint32_t body_offset
    buf_t *buffer
    slurm_persist_conn_t *conn
    int conn_fd
    void *data
    uint32_t data_size
    uint16_t flags
    uint8_t hash_index
    uint16_t msg_type
    uint16_t protocol_version
    forward_t forward
    forward_struct_t *forward_struct
    slurm_addr_t orig_addr
    List ret_list

# Slurm Protocol stuff
cdef extern void slurm_free_return_code_msg(return_code_msg_t *msg)
cdef extern int slurm_send_recv_controller_msg(slurm_msg_t *request_msg,
                                        slurm_msg_t *response_msg,
                                        slurmdb_cluster_rec_t *working_cluster_rec)

cdef extern void slurm_msg_t_init(slurm_msg_t *msg)

# https://github.com/SchedMD/slurm/blob/master/src/common/job_resources.h
ctypedef struct job_resources:
    bitstr_t *core_bitmap
    bitstr_t *core_bitmap_used
    uint32_t  cpu_array_cnt
    uint16_t *cpu_array_value
    uint32_t *cpu_array_reps
    uint16_t *cpus
    uint16_t *cpus_used
    uint16_t *cores_per_socket
    uint16_t  cr_type
    uint64_t *memory_allocated
    uint64_t *memory_used
    uint32_t  nhosts
    bitstr_t *node_bitmap
    uint32_t  node_req
    char	 *nodes
    uint32_t  ncpus
    uint32_t *sock_core_rep_count
    uint16_t *sockets_per_node
    uint16_t *tasks_per_node
    uint16_t  threads_per_core
    uint8_t   whole_node


# Global Environment
cdef extern char **environ

#
# Slurm Memory routines
# We simply use the macros from xmalloc.h - more convenient
#

cdef extern from "pyslurm/slurm/xmalloc.h" nogil:
    void xfree(void *__p)
    void *xmalloc(size_t __sz)
    void *try_xmalloc(size_t __sz) 
    void xfree_ptr(void *ptr)

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
cdef extern void slurm_free_update_step_msg(step_update_request_msg_t *msg)

#
# Slurm Node functions
#

cdef extern int slurm_get_select_nodeinfo(dynamic_plugin_data_t *nodeinfo, select_nodedata_type data_type, node_states state, void *data)
cdef extern char *slurm_node_state_string_complete(uint32_t inx)
cdef extern void slurm_free_update_node_msg(update_node_msg_t *msg)
cdef extern void slurm_free_node_info_members(node_info_t *node)

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
cdef extern void slurm_sprint_cpu_bind_type(char *str, cpu_bind_type_t cpu_bind_type)

# Slurm bit functions

cdef extern bitstr_t *slurm_bit_alloc(bitoff_t nbits)
cdef extern void slurm_bit_set(bitstr_t *b, bitoff_t bit)
cdef extern int slurm_bit_test(bitstr_t *b, bitoff_t bit)
cdef extern char *slurm_bit_fmt(char *str, int32_t len, bitstr_t *b)
cdef extern void slurm_bit_free(bitstr_t **b)


cdef extern from *:
    """
    #define bit_free(__b) slurm_bit_free((bitstr_t **)&(__b))
    #define FREE_NULL_BITMAP(_X)    \
    do {                            \
        if (_X)                     \
                bit_free(_X);       \
        _X = NULL;                  \
    } while(0)                      \
    """
    void bit_free(bitstr_t *_X)
    void FREE_NULL_BITMAP(bitstr_t *_X)

cdef extern char *slurm_hostlist_deranged_string_malloc(hostlist_t hl)
