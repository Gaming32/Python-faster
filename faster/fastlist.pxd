from cpython cimport PyObject


cdef int memsize_from_length(int length) nogil


cdef class fastlist:
    cdef PyObject** _array
    cdef int _length

    cdef object _cgetitem_int(self, int index)
    cdef fastlist _cgetitem_slice(self, slice indices)
    cdef void _csetitem_int(self, int index, object value) except *
    cdef void _csetitem_slice(self, slice indices, object value) except *
    cdef void _cdelitem_int(self, int index)
    cdef void _cdelitem_slice(self, slice index)
    cpdef void resize(self, int newlength) except *
    cpdef void append(self, object value) except *
    cpdef fastlist copy(self)
    cdef void _fast_extend(self, fastlist other) except *
    cpdef void extend(self, object other) except *
    cdef void multiply(self, int times) except *
    cpdef void insert(self, int i, object x) except *
    cpdef object pop(self, int i)
    cpdef void remove(self, object x, int starthint=?) except *
    cpdef void reverse_range(self, int start, int end) except *
    cpdef void reverse(self)
    cpdef int index(self, object x, int i=?, int j=?) except -1
    cpdef int count(self, object x)


cdef fastlist from_sequence(object seq)


cdef fastlist from_iterator(object it, int sizehint)
