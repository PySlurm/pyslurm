#########################################################################
# sbatch_opt.pyx - utilities to parse #SBATCH options
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

import re
from pathlib import Path

SBATCH_MAGIC = "#SBATCH"


class _SbatchOpt():
    def __init__(self, short_opt, long_opt,
                 our_attr_name, attr_param=None, is_boolean=False,
                 has_optional_args=False):
        self.short_opt = short_opt
        self.long_opt = long_opt
        self.our_attr_name = our_attr_name
        self.attr_param = attr_param
        self.is_boolean = is_boolean
        self.has_optional_args = has_optional_args


# Sorted by occurence in the sbatch manpage - keep in order.
SBATCH_OPTIONS = [
    _SbatchOpt("A", "account", "account"),
    _SbatchOpt(None, "acctg-freq", "accounting_gather_frequency"),
    _SbatchOpt("a", "array", "array"),
    _SbatchOpt(None, "batch", "batch_constraints"),
    _SbatchOpt(None, "bb", "burst_buffer"),
    _SbatchOpt(None, "bbf", "burst_buffer_file"),
    _SbatchOpt("b", "begin", "begin_time"),
    _SbatchOpt("D", "chdir", "working_directory"),
    _SbatchOpt(None, "cluster-constraint", "cluster_constraints"),
    _SbatchOpt("M", "clusters", "clusters"),
    _SbatchOpt(None, "comment","comment"),
    _SbatchOpt("C", "constraint", "constraints"),
    _SbatchOpt(None, "container", "container"),
    _SbatchOpt(None, "contiguous", "requires_contiguous_nodes"),
    _SbatchOpt("S", "core-spec", "cores_reserved_for_system"),
    _SbatchOpt(None, "cores-per-socket", "cores_per_socket"),
    _SbatchOpt(None, "cpu-freq", "cpu_frequency"),
    _SbatchOpt(None, "cpus-per-gpu", "cpus_per_gpu"),
    _SbatchOpt("c", "cpus-per-task", "cpus_per_task"),
    _SbatchOpt(None, "deadline", "deadline"),
    _SbatchOpt(None, "delay-boot", "delay_boot_time"),
    _SbatchOpt("d", "dependency", "dependencies"),
    _SbatchOpt("m", "distribution", "distribution"),
    _SbatchOpt("e", "error", "standard_error"),
    _SbatchOpt("x", "exclude", "excluded_nodes"),
    _SbatchOpt(None, "exclusive", "resource_sharing", "no"),
    _SbatchOpt(None, "export", "environment"),
    _SbatchOpt(None, "export-file", None),
    _SbatchOpt("B", "extra-node-info", None),
    _SbatchOpt(None, "get-user-env", "get_user_environment"),
    _SbatchOpt(None, "gid", "group_id"),
    _SbatchOpt(None, "gpu-bind", "gpu_binding"),
    _SbatchOpt(None, "gpu-freq", None),
    _SbatchOpt("G", "gpus", "gpus"),
    _SbatchOpt(None, "gpus-per-node", "gpus_per_node"),
    _SbatchOpt(None, "gpus-per-socket", "gpus_per_socket"),
    _SbatchOpt(None, "gpus-per-socket", "gpus_per_task"),
    _SbatchOpt(None, "gres", "gres_per_node"),
    _SbatchOpt(None, "gres-flags", "gres_binding"),
    _SbatchOpt(None, "hint", None),
    _SbatchOpt("H", "hold", "priority", 0),
    _SbatchOpt(None, "ignore-pbs", None),
    _SbatchOpt("i", "input", "standard_in"),
    _SbatchOpt("J", "job-name", "name"),
    _SbatchOpt(None, "kill-on-invalid-dep", "kill_on_invalid_dependency"),
    _SbatchOpt("L", "licenses", "licenses"),
    _SbatchOpt(None, "mail-type", "mail_types"),
    _SbatchOpt(None, "mail-user", "mail_user"),
    _SbatchOpt(None, "mcs-label", "mcs_label"),
    _SbatchOpt(None, "mem", "memory_per_node"),
    _SbatchOpt(None, "mem-bind", None),
    _SbatchOpt(None, "mem-per-cpu", "memory_per_cpu"),
    _SbatchOpt(None, "mem-per-gpu", "memory_per_gpu"),
    _SbatchOpt(None, "mincpus", "min_cpus_per_node"),
    _SbatchOpt(None, "network", "network"),
    _SbatchOpt(None, "nice", "nice"),
    _SbatchOpt("k", "no-kill", "kill_on_node_fail", False),
    _SbatchOpt(None, "no-requeue", "is_requeueable", False),
    _SbatchOpt("F", "nodefile", None),
    _SbatchOpt("w", "nodelist", "required_nodes"),
    _SbatchOpt("N", "nodes", "nodes"),
    _SbatchOpt("n", "ntasks", "ntasks"),
    _SbatchOpt(None, "ntasks-per-core", "ntasks_per_core"),
    _SbatchOpt(None, "ntasks-per-gpu", "ntasks_per_gpu"),
    _SbatchOpt(None, "ntasks-per-node", "ntasks_per_node"),
    _SbatchOpt(None, "ntasks-per-socket", "ntasks_per_socket"),
    _SbatchOpt(None, "open-mode", "log_files_open_mode"),
    _SbatchOpt("o", "output", "standard_output"),
    _SbatchOpt("O", "overcommit", "overcommit", True),
    _SbatchOpt("s", "oversubscribe", "resource_sharing", "yes"),
    _SbatchOpt("p", "partition", "partition"),
    _SbatchOpt(None, "power", "power_options"),
    _SbatchOpt(None, "prefer", None),
    _SbatchOpt(None, "priority", "priority"),
    _SbatchOpt(None, "profile", "profile_types"),
    _SbatchOpt(None, "propagate", None),
    _SbatchOpt("q", "qos", "qos"),
    _SbatchOpt(None, "reboot", "requires_node_reboot", True),
    _SbatchOpt(None, "requeue", "is_requeueable", True),
    _SbatchOpt(None, "reservation", "reservations"),
    _SbatchOpt(None, "signal", "signal"),
    _SbatchOpt(None, "sockets-per-node", "sockets_per_node"),
    _SbatchOpt(None, "spread-job", "spreads_over_nodes", True),
    _SbatchOpt(None, "switches", "switches"),
    _SbatchOpt(None, "thread-spec", "threads_reserved_for_system"),
    _SbatchOpt(None, "threads-per-core", "threads_per_core"),
    _SbatchOpt("t", "time", "time_limit"),
    _SbatchOpt(None, "time-min", "time_limit_min"),
    _SbatchOpt(None, "tmp", "temporary_disk_per_node"),
    _SbatchOpt(None, "uid", "user_id"),
    _SbatchOpt(None, "use-min-nodes", "use_min_nodes", True),
    _SbatchOpt(None, "wait-all-nodes", "wait_all_nodes", True),
    _SbatchOpt(None, "wckey", "wckey"),
]


def _parse_line(line):
    # Remove the #SBATCH from the start
    opts = line[len("#SBATCH"):]

    # Ignore possible comments after the options
    opts = opts.split("#")[0].strip()

    # Now the line can be in these forms for example:
    # * -t20 or -t 20
    # * --time=20 or --time 20 or --time20
    if "=" in opts:
        # -t=21 or --time=20
        opts = "=".join(opts.replace("=", " ").split())
        opt, val = opts.split("=")
    elif " " in opts:
        # --time 20 or -t 20
        opts = "=".join(opts.split())
        opt, val = opts.split("=")
    elif any(el.isdigit() for el in opts):
        # -t20 or --time20
        opt, val = list(filter(None, re.split(r'(\d+)', opts)))
    else:
        # Probably a boolean flag, like --exclusive or -O
        opt, val = opts, None

    # Remove "-" or "--" at the front.
    opt = opt[1:]
    if opt[0] == "-":
        # Found second dash.
        opt = opt[1:]

    return opt, val


def _find_opt(opt):
    for sbopt in SBATCH_OPTIONS:
        # Check if we can find the option in our predefined mapping.
        if opt == sbopt.short_opt or opt == sbopt.long_opt:
            return sbopt

    return None


def _parse_opts_from_batch_script(desc, script, overwrite):
    flags_and_vals = {}

    if not Path(script).is_file():
        raise ValueError("The script path you provided is not valid.")

    script = Path(script).read_text()
    for line in script.splitlines():
        line = line.lstrip()

        if line.startswith(SBATCH_MAGIC):
            flag, val = _parse_line(line)
            opt = _find_opt(flag)

            if not opt or opt.our_attr_name is None:
                # Not supported
                continue
            
            if getattr(desc, opt.our_attr_name) is None or overwrite:
                val = opt.attr_param if val is None else val
                setattr(desc, opt.our_attr_name, val)
