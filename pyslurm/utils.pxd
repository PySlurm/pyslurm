# cython: c_string_type=unicode, c_string_encoding=utf8

# 
# PySlurm Helper Functions
#

cdef inline strOrNone(char *value):
    if value is NULL:
        return None
    else:
        return value.decode("utf-8", "replace")


cdef inline list listOrNone(char *value):
    if value is NULL:
        return None
    else:
        return value.split(",")
