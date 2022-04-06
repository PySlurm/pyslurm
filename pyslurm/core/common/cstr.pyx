#########################################################################
# common/cstr.pyx - pyslurm string functions
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

import re

cdef bytes NULL_BYTE = "\0".encode("ascii")
cdef bytes NONE_BYTE = "None".encode("ascii")

cdef char *from_unicode(s):
    """Convert Python3 str (unicode) to char* (no malloc)

    Note
        The lifetime of this char* depends on the lifetime of the equivalent
        python-object passed in. If the python-object is gone, the char* cannot
        be used safely anymore.
    """
    if not s:
        return NULL

    _s = str(s)
    return _s


cdef inline to_unicode(char *_str, default=None):
    """Convert a char* to Python3 str (unicode)"""
    if _str and _str[0] != NULL_BYTE:
        if _str == NONE_BYTE:
            return None

        return _str
    else:
        return default


cdef fmalloc2(char **old, char **old2, val):
    """Like fmalloc, but copies the value to 2 char pointers.

    Memory will only be allocated once.
    "old" and "old2" will both share this same pointer.
    """
    fmalloc(old, val)
    old2[0] = old[0]


cdef fmalloc(char **old, val):
    """Try to free first and then create xmalloc'ed char* from str.

    Also see:
    https://github.com/SchedMD/slurm/blob/master/src/common/xstring.c#L454

    This function is essentially like xstrdup from Slurm, but also tries to free
    the previous allocation if needed.

    Uses Slurm's try_xmalloc for routine for allocating memory. try_xmalloc will
    return NULL if the allocation failed. We can check this and raise a
    MemoryError.

    Just using the normal xmalloc would call abort() if allocation failed (for
    example when OOM).
    """
    # TODO: Consider doing some size checks on the input by having an extra
    # argument like "max_size" which is configurable. Otherwise infinitely huge
    # strings could just be passed in and consume a lot of memory which would
    # allow for a denial of service attack on services that use pyslurm.
    cdef:
        const char *tmp = NULL
        size_t siz

    # Free the previous allocation (if neccessary)
    xfree(old[0])

    # Consider: Maybe every string containing a \0 should just
    # be rejected with an Exception instead of silently cutting
    # everything after \0 off?

    if val and val[0] != "\0":
        # Let Cython convert the Python-string to a char*
        # which will be NUL-terminated.
        tmp = val

        # Get the length of the char*, include space for NUL character
        siz = <size_t>strlen(tmp) + 1

        old[0] = <char *>slurm.try_xmalloc(siz)
        if not old[0]:
            raise MemoryError("xmalloc failed for char*")

        memcpy(old[0], tmp, siz)
    else:
        old[0] = NULL


cdef list to_list(char *str_list):
    """Convert C-String to a list."""
    cdef str ret = to_unicode(str_list)

    if not ret:
        return []

    return ret.split(",")


cdef from_list(char **old, vals, delim=","):
    """Convert list to a C-String."""
    cdef object final = vals

    if vals and not isinstance(vals, str):
        final = delim.join(vals)

    fmalloc(old, final)


cdef dict to_dict(char *str_dict, str delim1=",", str delim2="="):
    """Convert a char* key=value pair to dict.

    With a char* Slurm represents key-values pairs usually in the form of:
        key1=value1,key2=value2
    which can easily be converted to a dict.
    """
    cdef:
        str _str_dict = to_unicode(str_dict) 
        str key, val
        dict out = {}

    if not _str_dict:
        return out

    for kv in _str_dict.split(delim1):
        if delim2 in kv:
            key, val = kv.split(delim2)
            out[key] = val

    return out


cdef dict from_dict(char **old, vals, prepend=None, str delim1=",", str delim2="="):
    """Convert a dict (or str) to Slurm Key-Value pair.

    Slurm predominantly uses a format of:
        key1=value1,key2=value2,...

    for Key/Value type things, which can be easily created from a dict.

    A String which already has this form can also be passed in. The correct
    format of this string will the be validated.
    """
    cdef:
        out = {} if not vals else vals
        list tmp = []

    if vals and isinstance(vals, str):
        out = {}
        for kv in vals.split(delim1):
            if delim2 in kv:
                k, v = kv.split(delim2)
                out[k] = v
            else:
                raise ValueError(
                    f"Invalid format for key-value pair {kv}. "
                    f"Expected {delim2} as seperator."
                )
    
    for k, v in out.items():
        if ((delim1 in k or delim2 in k) or
                delim1 in v or delim2 in v):    
            raise ValueError(
                f"Key or Value cannot contain either {delim1} or {delim2}. "
                f"Got Key: {k} and Value: {v}."
            )

        tmp.append(f"{'' if not prepend else prepend}{k}{delim2}{v}")

    fmalloc(old, delim1.join(tmp))

    return out


cdef to_gres_dict(char *gres):
    """Parse a GRES string."""
    cdef:
        dict output = {}
        str gres_str = to_unicode(gres)

    if not gres_str or gres_str == "(null)":
        return {}

    for item in re.split(",(?=[^,]+?:)", gres_str):

        # Remove the additional "gres" specifier if it exists
        if "gres:" in item:
            item = item.replace("gres:", "")

        gres_splitted = re.split(
            ":(?=[^:]+?)", 
            item.replace("(", ":", 1).replace(")", "")
        )

        name, typ, cnt = gres_splitted[0], gres_splitted[1], 0 

        # Check if we have a gres type.
        if typ.isdigit():
            cnt = typ
            typ = None
        else:
            cnt = gres_splitted[2]

        # Dict Key-Name depends on if we have a gres type or not
        name_and_typ = f"{name}:{typ}" if typ else name

        if not "IDX" in gres_splitted:
            # Check if we need to parse the exact GRES index when coming from
            # job_resources_t.
            output[name_and_typ] = int(cnt)
        else:
            # Cover cases with IDX
            idx = gres_splitted[3] if not typ else gres_splitted[4]
            output[name_and_typ] = {
                "count": cnt,
                "indexes": idx,
            }
            
    return output


cdef from_gres_dict(vals, typ=""):
    final = []
    gres_dict = vals

    if not vals:
        return None

    if isinstance(vals, str) and not vals.isdigit():
        gres_dict = {}

        gres_list = vals.replace("gres:", "")
        for gres_str in gres_list.split(","):
            gres_and_type, cnt = gres_str.rsplit(":", 1)
            gres_dict.update({gres_and_type: int(cnt)})
    elif isinstance(vals, dict):
        for gres_and_type, cnt in gres_dict.items():
            # Error immediately on specifications that contain more than one
            # semicolon, as it is wrong.
            if len(gres_and_type.split(":")) > 2:
                raise ValueError(f"Invalid specifier: '{gres_and_type}'")

            if typ not in gres_and_type:
                gres_and_type = f"{gres_and_type}:{typ}"

            final.append(f"gres:{gres_and_type}:{int(cnt)}")
    else:
        return f"gres:{typ}:{int(vals)}"

    return ",".join(final)


cdef free_array(char **arr, count):
    for i in range(count):
        xfree(arr[i])

    xfree(arr)
