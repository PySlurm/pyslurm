#########################################################################
# helpers.pyx - basic helper functions
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

from os import WIFSIGNALED, WIFEXITED, WTERMSIG, WEXITSTATUS
from grp import getgrgid, getgrnam, getgrall
from pwd import getpwuid, getpwnam, getpwall
from os import getuid, getgid
from itertools import chain
import re
import signal
from pyslurm.constants import UNLIMITED


MEMORY_UNITS = {
    "K": 2**10.0,
    "M": 2**20.0,
    "G": 2**30.0,
    "T": 2**40.0,
    "P": 2**50.0,
    "E": 2**60.0,
    "Z": 2**70.0
}


cpdef uid_to_name(uint32_t uid, err_on_invalid=True, dict lookup={}):
    """Translate UID to a User-Name."""
    if uid == slurm.NO_VAL or uid == slurm.INFINITE:
        return None

    if lookup:
        try:
            name = lookup[uid]
            return name
        except KeyError as e:
            if err_on_invalid:
                raise e
    else:
        try:
            name = getpwuid(uid).pw_name
            return name
        except KeyError as e:
            if err_on_invalid:
                raise e

    return None


cpdef gid_to_name(uint32_t gid, err_on_invalid=True, dict lookup={}):
    """Translate a uid to a Group-Name."""
    if gid == slurm.NO_VAL or gid == slurm.INFINITE:
        return None

    if lookup:
        try:
            name = lookup[gid]
            return name
        except KeyError as e:
            if err_on_invalid:
                raise e
    else:
        try:
            name = getgrgid(gid).gr_name
            return name
        except KeyError as e:
            if err_on_invalid:
                raise e

    return None


def user_to_uid(user, err_on_invalid=True):
    """Translate User-Name to a uid."""
    if user is None:
        return slurm.NO_VAL

    try:
        if isinstance(user, str) and not user.isdigit():
            return getpwnam(user).pw_uid
        
        return getpwuid(int(user)).pw_uid
    except KeyError as e:
        if err_on_invalid:
            raise e

    return getuid()


def group_to_gid(group, err_on_invalid=True):
    """Translate a Group-Name to a gid."""
    if group is None:
        return slurm.NO_VAL

    try:
        if isinstance(group, str) and not group.isdigit():
            return getgrnam(group).gr_gid

        return getgrgid(int(group)).gr_gid
    except KeyError as e:
        if err_on_invalid:
            raise e

    return getgid()


def _getgrall_to_dict():
    cdef list groups = getgrall()
    cdef dict grp_info = {item.gr_gid: item.gr_name for item in groups}
    return grp_info


def _getpwall_to_dict():
    cdef list passwd = getpwall()
    cdef dict pw_info = {item.pw_uid: item.pw_name for item in passwd}
    return pw_info


def expand_range_str(range_str):
    """Expand a ranged string of numbers to a list of unique values.

    Args:
        range_str (str):
            A range string, which can for example look like this:
            "1,2,3-10,11,15-20"

    Returns:
        (list): List of unique values
    """
    ret = []
    for mrange in range_str.split(","):
        start, sep, end = mrange.partition("-")
        start = int(start)

        if sep:
            ret += range(start, int(end)+1)
        else:
            ret.append(start)

    return ret


def nodelist_from_range_str(nodelist):
    """Convert a bracketed nodelist str with ranges to a list.

    Args:
        nodelist (Union[str, list]):
            Comma-seperated str or list with potentially bracketed hostnames
            and ranges.

    Returns:
        (list): List of all nodenames or None on failure
    """
    if isinstance(nodelist, list):
        nodelist = ",".join(nodelist)

    cdef:
        char *nl = nodelist
        slurm.hostlist_t hl
        char *hl_unranged = NULL

    hl = slurm.slurm_hostlist_create(nl)
    if not hl:
        return []

    hl_unranged = slurm.slurm_hostlist_deranged_string_malloc(hl)
    out = cstr.to_list(hl_unranged)

    free(hl_unranged)
    slurm.slurm_hostlist_destroy(hl)

    return out


def nodelist_to_range_str(nodelist):
    """Convert a list of nodes to a bracketed str with ranges.

    Args:
        nodelist (Union[str, list]):
            Comma-seperated str or list with unique, unbracketed nodenames.

    Returns:
        (str): Bracketed, ranged nodelist or None on failure.
    """
    if isinstance(nodelist, list):
        nodelist = ",".join(nodelist)

    cdef:
        char *nl = nodelist
        slurm.hostlist_t hl
        char *hl_ranged = NULL
    
    hl = slurm.slurm_hostlist_create(nl)
    if not hl:
        return None

    hl_ranged = slurm.slurm_hostlist_ranged_string_malloc(hl)
    out = cstr.to_unicode(hl_ranged)

    free(hl_ranged)
    slurm.slurm_hostlist_destroy(hl)

    return out 


def humanize(num, decimals=1):
    """Humanize a number.

    This will convert the number to a string and add appropriate suffixes like
    M,G,T,P,...

    Args:
        num (int):
            Number to humanize
        decimals (int, optional):
            Amount of decimals the humanized string should have.

    Returns:
        (str): Humanized number with appropriate suffix.
    """
    if num is None or num == "unlimited" or num == UNLIMITED:
        return num

    num = int(num)
    for unit in ["M", "G", "T", "P", "E", "Z"]:
        if abs(num) < 1024.0:
            return f"{num:3.{decimals}f}{unit}"
        num /= 1024.0

    return f"{num:.{decimals}f}Y"


def dehumanize(humanized_str, target="M", decimals=0):
    """Dehumanize a previously humanized value.

    Args:
        humanized_str (str):
            A humanized str, for example "5M" or "10T"
        target (str):
            Target unit. The default is "M" (Mebibytes). Allowed values are
            K,M,G,T,P,E,Z
        decimals (int):
            Amount of decimal places the result should have. Default is 0

    Returns:
        (int): Dehumanized value
    """
    if not humanized_str:
        return None

    units_str = " ".join(MEMORY_UNITS.keys())
    splitted = re.split(f'([{units_str}])', str(humanized_str))

    if len(splitted) == 1:
        try:
            return int(humanized_str)
        except ValueError as e:
            raise ValueError(f"Invalid value specified: {humanized_str}")

    val = float(splitted[0])
    unit = splitted[1]

    val_in_bytes = val * MEMORY_UNITS[unit]
    val_in_target_size = float(val_in_bytes / MEMORY_UNITS[target])

    if not decimals:
        return round(val_in_target_size)
    else:
        return float(f"{val_in_target_size:.{decimals}f}")


def signal_to_num(sig):
    if not sig:
        return None

    try:
        if str(sig).isnumeric():
            _sig = signal.Signals(int(sig)).value
        else:
            _sig = signal.Signals[sig].value
    except Exception:
        raise ValueError(f"Invalid Signal: {sig}.") from None

    return _sig


def cpubind_to_num(cpu_bind):
    cdef uint32_t flags = 0

    if not cpu_bind:
        return flags

    cpu_bind = cpu_bind.casefold().split(",")

    if "none" in cpu_bind:
        flags |= slurm.CPU_BIND_NONE
    elif "sockets" in cpu_bind:
        flags |= slurm.CPU_BIND_TO_SOCKETS
    elif "ldoms" in cpu_bind:
        flags |= slurm.CPU_BIND_TO_LDOMS
    elif "cores" in cpu_bind:
        flags |= slurm.CPU_BIND_TO_CORES
    elif "threads" in cpu_bind:
        flags |= slurm.CPU_BIND_TO_THREADS
    elif "off" in cpu_bind:
        flags |= slurm.CPU_BIND_OFF
    if "verbose" in cpu_bind:
        flags |= slurm.CPU_BIND_VERBOSE

    return flags


def instance_to_dict(inst):
    cdef dict out = {}
    for attr in dir(inst):
        val = getattr(inst, attr)
        if attr.startswith("_") or callable(val):
            # Ignore everything starting with "_" and all functions.
            continue
        out[attr] = val

    return out


def collection_to_dict(collection, identifier, recursive=False, group_id=None):
    cdef dict out = {}

    for item in collection:
        cluster = item.cluster
        if cluster not in out:
            out[cluster] = {}

        _id = identifier.__get__(item)
        data = item if not recursive else item.as_dict()

        if group_id:
            grp_id = group_id.__get__(item)
            if grp_id not in out[cluster]:
                out[cluster][grp_id] = {}
            out[cluster][grp_id].update({_id: data})
        else:
            out[cluster][_id] = data

    return out


def collection_to_dict_global(collection, identifier, recursive=False):
    cdef dict out = {}
    for item in collection:
        _id = identifier.__get__(item)
        out[_id] = item if not recursive else item.as_dict()
    return out


def group_collection_by_cluster(collection):
    cdef dict out = {}
    collection_type = type(collection)

    for item in collection:
        cluster = item.cluster
        if cluster not in out:
            out[cluster] = collection_type()

        out[cluster].append(item)
    
    return out


def _sum_prop(obj, name, startval=0):
    val = startval
    for n in obj.values():
        v = name.__get__(n)
        if v is not None:
            val += v

    return val


def _get_exit_code(exit_code):
    exit_state=sig = 0
    if exit_code != slurm.NO_VAL:
        if WIFSIGNALED(exit_code):
            exit_state, sig = 0, WTERMSIG(exit_code)
        elif WIFEXITED(exit_code):
            exit_state, sig = WEXITSTATUS(exit_code), 0
            if exit_state >= 128:
                exit_state -= 128

    return exit_state, sig


def humanize_step_id(sid):
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


def dehumanize_step_id(sid):
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
