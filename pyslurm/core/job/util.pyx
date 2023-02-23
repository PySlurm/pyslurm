#########################################################################
# parse_types.pyx - utility functions used to parse various job flags
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

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from pyslurm cimport slurm
from pyslurm.core.common.uint import *
from pyslurm.core.common.uint cimport *


def parse_mail_type(mail_types):
    """Convert a str or list of mail types to a uint16_t."""
    cdef uint16_t flags = 0
    types = mail_types

    if not types or "None" == types:
        return slurm.NO_VAL16

    if isinstance(types, str):
        types = types.split(",")

    for typ in mail_types:
        typ = typ.casefold()

        if "array_tasks" == typ:
            flags |= slurm.MAIL_ARRAY_TASKS

        elif "begin" == typ:
            flags |= slurm.MAIL_JOB_BEGIN

        elif "end" == typ:
            flags |= slurm.MAIL_JOB_END

        elif "fail" == typ:
            flags |= slurm.MAIL_JOB_FAIL

    #    elif "invalid_depend" == typ:
    #        flags |= slurm.MAIL_INVALID_DEPEND

        elif "requeue" == typ:
            flags |= slurm.MAIL_JOB_REQUEUE

        elif "stage_out" == typ:
            flags |= slurm.MAIL_JOB_STAGE_OUT

        elif "time_limit" == typ:
            flags |= slurm.MAIL_JOB_TIME100

        elif "time_limit_90" == typ:
            flags |= slurm.MAIL_JOB_TIME90

        elif "time_limit_80" == typ:
            flags |= slurm.MAIL_JOB_TIME80

        elif "time_limit_50" == typ:
            flags |= slurm.MAIL_JOB_TIME50

        elif "all" == typ:
            flags |= (slurm.MAIL_JOB_BEGIN
                  |   slurm.MAIL_JOB_END
                  |   slurm.MAIL_JOB_FAIL
                  |   slurm.MAIL_JOB_REQUEUE
                  |   slurm.MAIL_JOB_STAGE_OUT)
        else:
            raise ValueError("Invalid Mail type: {typ}.")

    return flags


def get_mail_type(uint16_t typ):
    """Convert uint16_t to a list of mail types."""
    types = []

    if typ == 0:
        return types

    if typ & slurm.MAIL_ARRAY_TASKS:
        types.append("array_tasks")

#    if typ & slurm.MAIL_INVALID_DEPEND:
#        types.append("invalid_depend")

    if typ & slurm.MAIL_JOB_BEGIN:
        types.append("begin")

    if typ & slurm.MAIL_JOB_END:
        types.append("end")

    if typ & slurm.MAIL_JOB_FAIL:
        types.append("fail")

    if typ & slurm.MAIL_JOB_REQUEUE:
        types.append("requeue")

    if typ & slurm.MAIL_JOB_STAGE_OUT:
        types.append("stage_out")

    if typ & slurm.MAIL_JOB_TIME50:
        types.append("time_limit_50")

    if typ & slurm.MAIL_JOB_TIME80:
        types.append("time_limit_80")

    if typ & slurm.MAIL_JOB_TIME90:
        types.append("time_limit_90")

    if typ & slurm.MAIL_JOB_TIME100:
        types.append("time_limit_100")

    return types


def parse_acctg_profile(acctg_profiles):
    """Convert a str or list of accounting gather profiles to uin32_t."""
    cdef uint32_t profile = 0
    profiles = acctg_profiles

    if not acctg_profiles:
        return slurm.NO_VAL

    if "none" in acctg_profiles:
        return slurm.ACCT_GATHER_PROFILE_NONE
    elif "all" in acctg_profiles:
        return slurm.ACCT_GATHER_PROFILE_ALL

    if "energy" in acctg_profiles:
        profile |= slurm.ACCT_GATHER_PROFILE_ENERGY

    if "task" in acctg_profiles:
        profile |= slurm.ACCT_GATHER_PROFILE_TASK

    if "lustre" in acctg_profiles:
        profile |= slurm.ACCT_GATHER_PROFILE_LUSTRE

    if "network" in acctg_profiles:
        profile |= slurm.ACCT_GATHER_PROFILE_NETWORK

    return profile


def get_acctg_profile(flags):
    """Convert uin32_t accounting gather profiles to a list of strings."""
    profiles = []

    if flags == 0 or flags == slurm.NO_VAL:
        return ["none"]

    if flags == slurm.ACCT_GATHER_PROFILE_ALL:
        return ["all"]
    elif flags == slurm.ACCT_GATHER_PROFILE_NONE:
        return ["none"]

    if flags & slurm.ACCT_GATHER_PROFILE_ENERGY:
        profiles.append("energy")

    if flags & slurm.ACCT_GATHER_PROFILE_TASK:
        profiles.append("task")

    if flags & slurm.ACCT_GATHER_PROFILE_LUSTRE:
        profiles.append("lustre")

    if flags & slurm.ACCT_GATHER_PROFILE_NETWORK:
        profiles.append("network")

    return profiles


def parse_power_type(power_types):
    """Convert a str or list of str with power types to uint8_t."""
    cdef uint8_t flags = 0

    if not power_types:
        return slurm.NO_VAL8

    if "level" in power_types:
        flags |= slurm.SLURM_POWER_FLAGS_LEVEL


def get_power_type(flags):
    """Convert uint8_t power type flags to a list of strings."""
    types = []

    if flags & slurm.SLURM_POWER_FLAGS_LEVEL:
        types.append("level")

    return types


def parse_shared_type(typ):
    """Convert a job-sharing type str to its numerical representation."""
    if not typ:
        return slurm.NO_VAL16

    typ = typ.casefold()
    if typ == "oversubscribe" or typ == "yes":
        return slurm.JOB_SHARED_OK
    elif typ == "user":
        return slurm.JOB_SHARED_USER
    elif typ == "mcs":
        return slurm.JOB_SHARED_MCS
    elif typ == "no" or typ == "exclusive":
        return slurm.JOB_SHARED_NONE
    else:
        raise ValueError(f"Invalid resource_sharing type: {typ}.")


# https://github.com/SchedMD/slurm/blob/510ba4f17dfa559b579aa054cb8a415dcc224abc/src/common/proc_args.c#L319
def get_task_dist(dist):
    """Get the task distribution of a step as a dictionary."""
    out = {
        "nodes": None,
        "sockets": None,
        "cores": None,
        "plane": None,
        "pack": None,
    }

    if int(dist) <= 0 or dist == slurm.SLURM_DIST_UNKNOWN:
        return None

    if (dist & slurm.SLURM_DIST_STATE_BASE) != slurm.SLURM_DIST_UNKNOWN:
        state = dist & slurm.SLURM_DIST_STATE_BASE

        if state == slurm.SLURM_DIST_BLOCK:
            out["nodes"] = "block"
        elif state == slurm.SLURM_DIST_CYCLIC:
            out["nodes"] = "cyclic"
        elif state == slurm.SLURM_DIST_PLANE:
            pass
        elif state == slurm.SLURM_DIST_ARBITRARY:
            out["nodes"] = "arbitrary"
        elif state == slurm.SLURM_DIST_CYCLIC_CYCLIC:
            out["nodes"] = "cyclic"
            out["sockets"] = "cyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_BLOCK:
            out["nodes"] = "cyclic"
            out["sockets"] = "block"
        elif state == slurm.SLURM_DIST_CYCLIC_CFULL:
            out["nodes"] = "cyclic"
            out["sockets"] = "fcyclic"
        elif state == slurm.SLURM_DIST_BLOCK_CYCLIC:
            out["nodes"] = "block"
            out["sockets"] = "cyclic"
        elif state == slurm.SLURM_DIST_BLOCK_BLOCK:
            out["nodes"] = "block"
            out["sockets"] = "block"
        elif state == slurm.SLURM_DIST_BLOCK_CFULL:
            out["nodes"] = "block"
            out["sockets"] = "fcyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_CYCLIC_CYCLIC:
            out["nodes"] = "cyclic"
            out["sockets"] = "cyclic"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_CYCLIC_BLOCK:
            out["nodes"] = "cyclic"
            out["sockets"] = "cyclic"
            out["cores"] = "block"
        elif state == slurm.SLURM_DIST_CYCLIC_CYCLIC_CFULL:
            out["nodes"] = "cyclic"
            out["sockets"] = "cyclic"
            out["cores"] = "fcyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_BLOCK_CYCLIC:
            out["nodes"] = "cyclic"
            out["sockets"] = "block"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_BLOCK_CYCLIC:
            out["nodes"] = "cyclic"
            out["sockets"] = "block"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_BLOCK_BLOCK:
            out["nodes"] = "cyclic"
            out["sockets"] = "block"
            out["cores"] = "block"
        elif state == slurm.SLURM_DIST_CYCLIC_BLOCK_CFULL:
            out["nodes"] = "cyclic"
            out["sockets"] = "block"
            out["cores"] = "fcyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_CFULL_CYCLIC:
            out["nodes"] = "cyclic"
            out["sockets"] = "fcyclic"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_CYCLIC_CFULL_BLOCK:
            out["nodes"] = "cyclic"
            out["sockets"] = "fcyclic"
            out["cores"] = "block"
        elif state == slurm.SLURM_DIST_CYCLIC_CFULL_CFULL:
            out["nodes"] = "cyclic"
            out["sockets"] = "fcyclic"
            out["cores"] = "fcyclic"
        elif state == slurm.SLURM_DIST_BLOCK_CYCLIC_CYCLIC:
            out["nodes"] = "block"
            out["sockets"] = "cyclic"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_BLOCK_CYCLIC_BLOCK:
            out["nodes"] = "block"
            out["sockets"] = "cyclic"
            out["cores"] = "block"
        elif state == slurm.SLURM_DIST_BLOCK_CYCLIC_CFULL:
            out["nodes"] = "block"
            out["sockets"] = "cyclic"
            out["cores"] = "fcyclic"
        elif state == slurm.SLURM_DIST_BLOCK_BLOCK_CYCLIC:
            out["nodes"] = "block"
            out["sockets"] = "block"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_BLOCK_BLOCK_BLOCK:
            out["nodes"] = "block"
            out["sockets"] = "block"
            out["cores"] = "block"
        elif state == slurm.SLURM_DIST_BLOCK_BLOCK_CFULL:
            out["nodes"] = "block"
            out["sockets"] = "block"
            out["cores"] = "fcyclic"
        elif state == slurm.SLURM_DIST_BLOCK_CFULL_CYCLIC:
            out["nodes"] = "block"
            out["sockets"] = "fcyclic"
            out["cores"] = "cyclic"
        elif state == slurm.SLURM_DIST_BLOCK_CFULL_BLOCK:
            out["nodes"] = "block"
            out["sockets"] = "fcyclic"
            out["cores"] = "block"
        elif state == slurm.SLURM_DIST_BLOCK_CFULL_CFULL:
            out["nodes"] = "block"
            out["sockets"] = "fcyclic"
            out["cores"] = "fcyclic"
        else:
            out = None

    if out is not None:
        dist_flag = dist & slurm.SLURM_DIST_STATE_FLAGS
        if dist_flag == slurm.SLURM_DIST_PACK_NODES:
            out["pack"] = True
        elif dist_flag == slurm.SLURM_DIST_NO_PACK_NODES:
            out["pack"] = False
        
    return out


def parse_task_dist(dist):
    """Parse a distribution str or dict to its numerical representation."""
    cdef slurm.task_dist_states_t dist_state = slurm.SLURM_DIST_UNKNOWN

    if not dist:
        return dist_state, None

    # Assume the user meant to specify the plane size.
    if isinstance(dist, int):
        return None, u16(dist)

    # Support sbatch-style string input.
    # Parse the string and fill in the dist_dict above.
    if isinstance(dist, str):
        dist_str = dist

        # Plane method - return early because nothing else can be
        # specified when this is set.
        if "plane" in dist_str:
            return None, u16(dist_str.split("=", 1)[1])

        dist = {
            "nodes": None,
            "sockets": None,
            "cores": None,
            "plane": None,
            "pack": None,
        }

        # [0] = distribution method for nodes:sockets:cores
        # [1] = pack/nopack specification (true or false)
        dist_items = dist_str.split(",", 1)

        # Parse the different methods and fill in the dist_dict.
        dist_methods = dist_items[0].split(":")
        if len(dist_methods) and dist_methods[0] != "*":
            dist["nodes"] = dist_methods[0]

        if len(dist_methods) > 2 and dist_methods[1] != "*":
            dist["sockets"] = dist_methods[1]

        if len(dist_methods) >= 3:
            if dist_methods[2] == "*":
                dist["cores"] = dist_dict["sockets"]
            else:
                dist["cores"] = dist_methods[2]
        
        if len(dist_items) > 1:
            if dist_items[1].casefold() == "pack":
                dist["pack"] = True
            elif dist_items[1].casefold() == "nopack":
                dist["pack"] = False

    # Plane method - return early because nothing else can be
    # specified when this is set.
    if dist.get("plane") is not None:
        return None, u16(dist['plane'])

    dist_str = ""
    sockets_dist = None

    # Join the dist_dict distribution methods into a dist_str
    # for easier comparison to check which distribution state
    # is needed (see below).
    nodes = dist.get("nodes")
    if nodes is not None and nodes != "*":
        dist_str = f"{nodes}"
    else:
        dist_str = "block"

    sockets = dist.get("sockets")
    if sockets is not None and sockets != "*":
        dist_str = f"{dist_str}:{sockets}"
    else:
        dist_str = f"{dist_str}:cyclic"

    cores = dist.get("cores")
    if cores is not None and cores != "*":
        dist_str = f"{dist_str}:{cores}"
    else:
        dist_str = f"{dist_str}:{sockets}"

    # Select the correct distribution method according to dist_str.
    if dist_str == "cyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC
    elif dist_str == "block":
        dist_state = slurm.SLURM_DIST_BLOCK
    elif dist_str == "arbitrary" or dist_str == "hostfile":
        dist_state = slurm.SLURM_DIST_ARBITRARY
    elif dist_str == "cyclic:cyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_CYCLIC
    elif dist_str == "cyclic:block":
        dist_state = slurm.SLURM_DIST_CYCLIC_BLOCK
    elif dist_str == "block:block":
        dist_state = slurm,SLURM_DIST_BLOCK_BLOCK
    elif dist_str == "block:cyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_CYCLIC
    elif dist_str == "block:fcyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_CFULL
    elif dist_str == "cyclic:fcyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_CFULL
    elif dist_str == "cyclic:cyclic:cyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_CYCLIC_CYCLIC
    elif dist_str == "cyclic:cyclic:block":
        dist_state = slurm.SLURM_DIST_CYCLIC_CYCLIC_BLOCK
    elif dist_str == "cyclic:cyclic:fcyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_CYCLIC_CFULL
    elif dist_str == "cyclic:block:cyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_BLOCK_CYCLIC
    elif dist_str == "cyclic:block:block":
        dist_state = slurm.SLURM_DIST_CYCLIC_BLOCK_BLOCK
    elif dist_str == "cyclic:block:fcyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_BLOCK_CFULL
    elif dist_str == "cyclic:fcyclic:cyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_CFULL_CYCLIC
    elif dist_str == "cyclic:fcyclic:block":
        dist_state = slurm.SLURM_DIST_CYCLIC_CFULL_BLOCK
    elif dist_str == "cyclic:fcyclic:fcyclic":
        dist_state = slurm.SLURM_DIST_CYCLIC_CFULL_CFULL
    elif dist_str == "block:cyclic:cyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_CYCLIC_CYCLIC
    elif dist_str == "block:cyclic:block":
        dist_state = slurm.SLURM_DIST_BLOCK_CYCLIC_BLOCK
    elif dist_str == "block:cyclic:fcyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_CYCLIC_CFULL
    elif dist_str == "block:block:cyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_BLOCK_CYCLIC
    elif dist_str == "block:block:block":
        dist_state = slurm.SLURM_DIST_BLOCK_BLOCK_BLOCK
    elif dist_str == "block:block:fcyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_BLOCK_CFULL
    elif dist_str == "block:fcyclic:cyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_CFULL_CYCLIC
    elif dist_str == "block:fcyclic:block":
        dist_state = slurm.SLURM_DIST_BLOCK_CFULL_BLOCK
    elif dist_str == "block:fcyclic:fcyclic":
        dist_state = slurm.SLURM_DIST_BLOCK_CFULL_CFULL
    else:
        raise ValueError(f"Invalid distribution specification: {dist}")

    # Check for Pack/NoPack
    # Don't do anything if dist["pack"] is None
    if dist["pack"]:
        dist_state = <slurm.task_dist_states_t>(dist_state | slurm.SLURM_DIST_PACK_NODES)
    elif dist["pack"] is not None and not dist["pack"]:
        dist_state = <slurm.task_dist_states_t>(dist_state | slurm.SLURM_DIST_NO_PACK_NODES)

    return dist_state, None


def parse_cpu_gov(gov): 
    """Convert a cpu governor str to is numerical representation."""
    if not gov:
        return u32(None)

    gov = gov.casefold()
    rc = 0

    if gov == "conservative":
        rc = slurm.CPU_FREQ_CONSERVATIVE
    elif gov == "ondemand":
        rc = slurm.CPU_FREQ_ONDEMAND
    elif gov == "performance":
        rc = slurm.CPU_FREQ_PERFORMANCE
    elif gov == "powersave":
        rc = slurm.CPU_FREQ_POWERSAVE
    elif gov == "userspace":
        rc = slurm.CPU_FREQ_USERSPACE
    elif gov == "schedutil":
        rc = slurm.CPU_FREQ_SCHEDUTIL
    else:
        raise ValueError("Invalid cpu gov type: {}".format(gov))

    return rc | slurm.CPU_FREQ_RANGE_FLAG


def parse_cpufreq(freq):
    """Convert a cpu-frequency str to its numerical representation."""
    if not freq:
        return u32(None)

    if isinstance(freq, str) and not freq.isdigit():
        freq = freq.casefold()

        if freq == "low":
            return slurm.CPU_FREQ_LOW
        elif freq == "highm1":
            return slurm.CPU_FREQ_HIGHM1
        elif freq == "high":
            return slurm.CPU_FREQ_HIGH
        elif freq == "medium":
            return slurm.CPU_FREQ_MEDIUM
    else:
        fr = u32(int(freq))
        if fr != slurm.NO_VAL:
            return fr

    raise ValueError(f"Invalid cpu freq value: {freq}.")


def cpufreq_to_str(freq):
    """Convert a numerical cpufreq value to its string representation."""
    if freq == slurm.CPU_FREQ_LOW:
        return "Low"
    elif freq == slurm.CPU_FREQ_MEDIUM:
        return "Medium"
    elif freq == slurm.CPU_FREQ_HIGHM1:
        return "Highm1"
    elif freq == slurm.CPU_FREQ_HIGH:
        return "High"
    elif freq == slurm.CPU_FREQ_CONSERVATIVE:
        return "Conservative"
    elif freq == slurm.CPU_FREQ_PERFORMANCE:
        return "Performance"
    elif freq == slurm.CPU_FREQ_POWERSAVE:
        return "PowerSave"
    elif freq == slurm.CPU_FREQ_USERSPACE:
        return "UserSpace"
    elif freq == slurm.CPU_FREQ_ONDEMAND:
        return "OnDemand"
    elif freq == slurm.CPU_FREQ_SCHEDUTIL:
        return "SchedUtil"
    elif freq & slurm.CPU_FREQ_RANGE_FLAG:
        return None
    elif freq == slurm.NO_VAL or freq == 0:
        return None
    else:
        # This is in kHz
        return freq


