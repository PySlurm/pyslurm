# 
# PySlurm Helper Functions
#
cimport cpython

cdef extern from "string.h":
    size_t strlen(char *s)


cdef unicode tounicode(char* s):
    if s == NULL:
        return None
    else:
        #return s.decode("UTF-8", "replace")
        return cpython.PyUnicode_DecodeUTF8(s, strlen(s), "replace")
