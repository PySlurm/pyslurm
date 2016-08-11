from libc.stdint cimport uint32_t

cdef unicode tounicode(char* s)
cdef secs2time_str(uint32_t time)
cdef mins2time_str(uint32_t time)
