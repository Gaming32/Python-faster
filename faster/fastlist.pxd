from cpython cimport PyObject


cdef class fastlist:
    cdef PyObject** _array
    cdef int _length
