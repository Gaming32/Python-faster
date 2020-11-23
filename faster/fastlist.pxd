from cpython cimport PyObject


cdef class fastlist:
    cdef PyObject** _array
    cdef int _length
    
    cdef object _cgetitem_int(self, int index)
    cdef object _cgetitem_slice(self, slice indices)
    cdef void _csetitem_int(self, int index, object value)
    cdef void _csetitem_slice(self, slice indices, object value)
