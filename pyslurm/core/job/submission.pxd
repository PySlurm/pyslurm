#########################################################################
# submission.pxd - interface for submitting slurm jobs
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
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: language_level=3

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    job_desc_msg_t,
    slurm_init_job_desc_msg,
    slurm_free_job_desc_msg,
    submit_response_msg_t,
    slurm_submit_batch_job,
    slurm_free_submit_response_response_msg,
    slurm_env_array_free,
    slurm_env_array_create,
    slurm_env_array_merge,
    slurm_env_array_overwrite,
    slurm_job_share_string,
    xfree,
    try_xmalloc,
)


cdef class JobSubmitDescription:
    cdef:
        slurm.job_desc_msg_t *ptr
        is_update

    cdef public:
        parse_sbatch_options

        name
        """str: Name of the Job.

        This is the same as -J/--job-name from sbatch.
        """

        account
        """str: Account this Job should run under.

        This is the same as -A/--account from sbatch.
        """

        uid
        """Union[str, int]: Under which user the job will be executed.

        For setting this value, you can both specify the name or numeric
        uid of the User. 

        This is the same as --uid from sbatch.
        """

        gid
        """Union[str, int]: Under which group the job will be executed.

        For setting this value, you can both specify the name or numeric
        gid of the Group. of the User.

        This is the same as --gid from sbatch.
        """

        priority
        """int: A specific Priority the Job will receive.

        You can achieve the behaviour of sbatch's --hold option by
        specifying a priority of 0.

        This is the same as --priority from sbatch.
        """

        site_factor
        """int: Site Factor for the Job.

        This is only used for updating an already existing Job. It will
        not be honored in the job submission.
        """

        wckey
        """str: WCKey to be used with the Job.

        This is the same as --wckey from sbatch.
        """

        array
        """str: An Array specification for the Job

        This is the same as -a/--array from sbatch.
        """

        batch_constraints
        """str: Batch Features for a Job

        This is the same as --batch from sbatch.
        """

        begin_time
        """str: Defer allocation until the specified time.

        This is the same as --begin from sbatch.
        """

        clusters
        """Union[list, str]: Clusters the job may run on.

        This is the same as -M/--clusters from sbatch.
        """

        cluster_constraints
        """str: Comma-separated str with cluster constraints for the job.

        This is the same as --cluster-constraint from sbatch.
        """

        comment
        """str: An arbitrary comment for the job.

        This is the same as --comment from sbatch.
        """

        admin_comment
        """str: An arbitrary admin-comment for the job

        This is only used when updating an already existing Job. Setting
        it for new Submissions does nothing.
        """
        
        contiguous
        """bool: Whether allocated Nodes should form a contiguous set

        This is the same as --contiguous from sbatch.
        """

        cores_reserved_for_system
        """int: Count of cores reserved for system not usable by the Job.

        This is the same as -S/--core-spec from sbatch.
        This is mutually exclusive with `threads_reserved_for_system`.
        """

        threads_reserved_for_system
        """int: Count of threads reserved for system not usable by the Job.

        This is the same as --thread-spec from sbatch.
        This is mutually exclusive with `cores_reserved_for_system`.
        """

        work_dir
        """str: Work directory for the job. Default is current work-dir.

        This is the same as -D/--chdir from sbatch.
        """

        cpu_freq
        """Union[dict, str]: Specify the CPU Frequency for the Job.

        This is the same as --cpu-freq from sbatch.

        Examples:
            Specifying it as a dict:

            cpu_freq = {
                "min": "Low",
                "max": "High",
                "governor": "UserSpace"
            }

            or like in sbatch with a string. For more info on that, check out
            the sbatch documentation for --cpu-freq.

            If you only want to set a Governor without any min or max, you can
            simply specify it as a standalone string:

            cpu_freq = "Performance"
            or
            cpu_freq = {"governor": "Performance"}

            If you want to set a specific, fixed frequency, you can do:

            cpu_freq = <frequency in kilohertz>
            or either
            cpu_freq = {"max": <freq>} or cpu_freq = {"min": <freq>}
        """

        nodes
        """Union[dict, str, int]: Amount of nodes needed for the job.

        This is the same as -N/--nodes from sbatch.

        Examples:
            Providing min/max nodes as a dict:

            nodes = {
                "min": 3,
                "max": 6
            }

            When no range is needed, you can also simply specify it as int:

            nodes = 3

            Other than that, a range can also be specified in a str like with
            sbatch:

            nodes = "1-5"
        """

        deadline
        """str: Deadline specification for the Job.

        This is the same as --deadline from sbatch.
        """

        delay_boot
        """Union[str, int]: Delay boot specification for the Job.

        This is the same as --delay-boot from sbatch.
        """

        dependencies
        """Union[dict, str]: Dependencies for the Job.

        This is the same as -d/--dependency from sbatch.
        """

        excluded_nodes
        """Union[list, str]: Exclude specific nodes for this Job.

        This is the same as -x/--exclude from sbatch.
        """

        required_nodes
        """Union[list, str]: Specific list of nodes required for the Job.

        This is the same as -w/--nodelist from sbatch.
        """

        constraints
        """str: Required node features for the Job.

        This is the same as -C/--constraint from sbatch.
        """

        kill_on_node_fail
        """bool: Should the job get killed if one of the Nodes fails?

        This is the same as -k/--no-kill from sbatch.
        """

        licenses
        """Union[list, str]: A list of licenses for the Job.

        This is the same as -L/--licenses from sbatch.
        """

        mail_user
        """Union[list, str]: List of email addresses for notifications.

        This is the same as --mail-user from sbatch.
        """

        mail_type
        """Union[list, str]: List of mail flags.

        This is the same as --mail-type from sbatch.
        """

        mcs_label
        """str: An MCS Label for the Job.

        This is the same as --mcs-label from sbatch.
        """

        mem_per_cpu
        """Union[str, int]: Memory required per allocated CPU. 

        The default unit is in Mebibytes. You are also able to specify unit
        suffixes like K|M|G|T.
        This is the same as --mem-per-cpu from sbatch.
        This is mutually exclusive with mem_per_node and mem_per_gpu.

        Examples:
            # 1 MiB
            mem_per_cpu = 1024

            # 3 GiB
            mem_per_cpu = "3G"
        """

        mem_per_node
        """Union[str, int]: Memory required per whole node.

        The default unit is in Mebibytes. You are also able to specify unit
        suffixes like K|M|G|T.
        This is the same as --mem from sbatch.
        This is mutually exclusive with mem_per_cpu and mem_per_gpu.

        Examples:
            # 1 MiB
            mem_per_node = 1024

            # 3 GiB
            mem_per_node = "3G"
        """

        mem_per_gpu
        """Union[str, int]: Memory required per GPU.

        The default unit is in Mebibytes. You are also able to specify unit
        suffixes like K|M|G|T.
        This is the same as --mem-per-gpu from sbatch.
        This is mutually exclusive with mem_per_node and mem_per_cpu.

        Examples:
            # 1 MiB
            mem_per_gpu = 1024

            # 3 GiB
            mem_per_gpu = "3G"
        """

        network
        """str: Network types for the Job.

        This is the same as --network from sbatch.
        """

        nice
        """int: Adjusted scheduling priority for the Job.

        This is the same as --nice from sbatch.
        """

        log_files_open_mode
        """str: Mode in which stdout and stderr log files should be opened. 

        Valid options are:
            * append
            * truncate

        This is the same as --open-mode from sbatch.
        """

        overcommit
        """bool: If the resources should be overcommitted.

        This is the same as -O/--overcommit from sbatch.
        """

        partitions
        """Union[list, str]: A list of partitions the Job may use.
        
        This is the same as -p/--partition from sbatch.
        """

        power_options
        """list: A list of power management plugin options for the Job.

        This is the same as --power from sbatch.
        """

        profile
        """list: List of types for the acct_gather_profile plugin.

        This is the same as --profile from sbatch.
        """

        accounting_gather_freq
        """Union[dict, str]: Interval for accounting info to be gathered.

        This is the same as --acctg-freq from sbatch.

        Examples:
            Specifying it as a dict:

            accounting_gather_freq = {
                energy=60,
                network=20,
            }

            or as a single string:

            accounting_gather_freq = "energy=60,network=20"
        """

        qos
        """str: Quality of Service for the Job.

        This is the same as -q/--qos from sbatch.
        """

        reboot_nodes
        """bool: Force the allocated nodes to reboot before the job starts.

        This is the same --reboot from sbatch.
        """

        is_requeueable
        """bool: If the Job is eligible for requeuing.

        This is the same as --requeue from sbatch.
        """

        reservations
        """Union[list, str]: A list of possible reservations the Job can use.

        This is the same as --reservation from sbatch.
        """

        script
        """str: Absolute Path or content of the batch script.

        You can specify either a path to a script which will be loaded, or
        you can pass the script as a string.
        If the script is passed as a string, providing arguments to it
        (see "script_args") is not supported.
        """

        script_args
        """str: Arguments passed to the batch script.

        You can only set arguments if a file path was specified for "script".
        """

        environment
        """Union[dict, str]: Environment variables to be set for the Job.

        This is the same as --export from sbatch.
        """

        resource_sharing
        """str: Controls the resource sharing with other Jobs.
        
        This property combines functionality of --oversubscribe and
        --exclusive from sbatch.

        Allowed values are are:

        * "oversubscribe" or "yes":
            The Job allows resources to be shared with other running Jobs.

        * "user" 
            Only sharing resources with other Jobs that have the "user" option
            set is allowed

        * "mcs" 
            Only sharing resources with other Jobs that have the "mcs" option
            set is allowed.

        * "no" or "exclusive"
            No sharing of resources is allowed. (--exclusive from sbatch)
        """

        distribution
        """TODO"""

        time_limit
        """str: The time limit for the job.

        This is the same as -t/--time from sbatch.
        """

        time_limit_min
        """str: A minimum time limit for the Job.

        This is the same as --time-min from sbatch.
        """

        container
        """str: Path to an OCI container bundle.

        This is the same as --container from sbatch.
        """

        cpus_per_task
        """int: The amount of cpus required for each task.

        This is the same as -c/--cpus-per-task from sbatch.
        This is mutually exclusive with cpus_per_gpu.
        """

        cpus_per_gpu
        """int: The amount of cpus required for each allocated GPU.

        This is the same as --cpus-per-gpu from sbatch.
        This is mutually exclusive with cpus_per_task.
        """

        sockets_per_node
        """int: Restrict Job to nodes with atleast this many sockets.

        This is the same as --sockets-per-node from sbatch.
        """

        cores_per_socket
        """int: Restrict Job to nodes with atleast this many cores per socket

        This is the same as --cores-per-socket from sbatch.
        """

        threads_per_core
        """int: Restrict Job to nodes with atleast this many threads per socket

        This is the same as --threads-per-core from sbatch.
        """

        gpus
        """Union[dict, str, int]: GPUs for the Job to be allocated in total.

        This is the same as -G/--gpus from sbatch.
        Specifying the type of the GPU is optional. 

        Examples:
            Specifying the GPU counts as a dict:

            gpus = {
                "tesla": 1,
                "volta": 5,
            }

            Or, for example, in string format:

            gpus = "tesla:1,volta:5"

            Or, if you don't care about the type of the GPU:

            gpus = 6
        """

        gpus_per_socket
        """Union[dict, str, int]: GPUs for the Job to be allocated per socket.

        This is the same as --gpus-per-socket from sbatch.

        Specifying the type of the GPU is optional. Note that setting
        gpus_per_socket requires to also specify sockets_per_node.

        Examples:
            Specifying it as a dict:

            gpus_per_socket = {
                "tesla": 1,
                "volta": 5,
            }

            Or, for example, in string format:

            gpus_per_socket = "tesla:1,volta:5"

            Or, if you don't care about the type of the GPU:

            gpus_per_socket = 6
        """

        gpus_per_task
        """Union[dict, str, int]: GPUs for the Job to be allocated per task.

        This is the same as --gpus-per-task from sbatch.

        Specifying the type of the GPU is optional. Note that setting
        "gpus_per_task" requires to also specify either one of "ntasks" or
        "gpus".

        Examples:
            Specifying it as a dict:

            gpus_per_task = {
                "tesla": 1,
                "volta": 5,
            }

            Or, for example, in string format:

            gpus_per_task = "tesla:1,volta:5"

            Or, if you don't care about the type of the GPU:

            gpus_per_task = 6
        """

        gres_per_node
        """Union[dict, str]: Generic resources to be allocated per node.

        This is the same as --gres from sbatch. You should also use this
        option if you want to specify GPUs per node (--gpus-per-node).
        Specifying the type (by seperating GRES name and type with a
        semicolon) is optional. 

        Examples:
            Specifying it as a dict:

            gres_per_node = {
                "gpu:tesla": 1,
                "gpu:volta": 5,
            }

            Or, for example, in string format:

            gres_per_node = "gpu:tesla:1,gpu:volta:5"

            GPU Gres without a specific type:

            gres_per_node = "gpu:6"
        """

        gpu_binding
        """str: Specify GPU binding for the Job.

        This is the same as --gpu-bind from sbatch.
        """

        ntasks
        """int: Maximum amount of tasks for the Job.

        This is the same as -n/--ntasks from sbatch.
        """

        ntasks_per_node
        """int: Amount of tasks to be invoked on each node.

        This is the same as --ntasks-per-node from sbatch.
        """

        ntasks_per_socket
        """int: Maximum amount of tasks to be invoked on each socket.

        This is the same as --ntasks-per-socket from sbatch.
        """

        ntasks_per_core
        """int: Maximum amount of tasks to be invoked on each core.

        This is the same as --ntasks-per-core from sbatch.
        """

        ntasks_per_gpu
        """int: Amount of tasks to be invoked per GPU.

        This is the same as --ntasks-per-socket from sbatch.
        """

        switches
        """Union[dict, str, int]: Maximum amount of leaf switches desired.

        This can also optionally include a maximum waiting time for these
        switches.
        This is the same as --switches from sbatch.

        Examples: 
            Specifying it as a dict:

            switches = { "count": 5, "max_wait_time": "00:10:00" }

            Or as a single string (sbatch-style):

            switches = "5@00:10:00"
        """

        signal
        """Union[dict, str]: Warn signal to be sent to the Job.

        This is the same as --signal from sbatch.
        The signal can both be specified with its name, e.g. "SIGKILL", or
        as a number, e.g. 9

        Examples:
            Specifying it as a dict:

            signal = {
                "signal": "SIGKILL",
                "time": 120
            }

            The above will send a "SIGKILL" signal 120 seconds before the
            Jobs' time limit is reached.

            Or, specifying it as a string (sbatch-style):

            signal = "SIGKILL@120"
        """ 

        stdin
        """str: Path to a File acting as stdin for the batch-script.

        This is the same as -i/--input from sbatch.
        """

        stdout
        """str: Path to a File to write the Jobs stdout.

        This is the same as -o/--output from sbatch.
        """

        stderr
        """str: Path to a File to write the Jobs stderr.

        This is the same as -e/--error from sbatch.
        """

        kill_on_invalid_dependency
        """bool: Kill the job if it has an invalid dependency.

        This is the same as --kill-on-invalid-dep from sbatch.
        """

        spread_job
        """bool: Spread the Job over as many nodes as possible.

        This is the same as --spread-job from sbatch.
        """

        use_min_nodes
        """bool: Prefer the minimum amount of nodes specified.

        This is the same as --use-min-nodes from sbatch.
        """

        gres_flags
        """str: Generic resource task binding options.

        This is the --gres-flags option from sbatch.

        Possible values are:
            * "enforce-binding"
            * "disable-binding"
        """

        tmp_disk_per_node
        """Union[str, int]: Amount of temporary disk space needed per node.

        This is the same as --tmp from sbatch. You can specify units like
        K|M|G|T (multiples of 1024).
        If no unit is specified, the value will be assumed as Mebibytes.

        Examples:
            # 2048 MiB
            tmp_disk_per_node = "2G"

            # 1024 MiB
            tmp_disk_per_node = 1024
        """

        get_user_environment
        """TODO"""

        min_cpus_per_node
        """str: Set the minimum amount of CPUs required per Node.

        This is the same as --mincpus from sbatch.
        """

        wait_all_nodes
        """bool: Controls when the execution of the command begins.

        A value of True means that the Job should begin execution only after
        all nodes in the allocation are ready. Setting it to False, the
        default, means that it is not waited for the nodes to be ready. (i.e
        booted)
        """

