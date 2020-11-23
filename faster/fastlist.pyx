from cython cimport sizeof
from cpython cimport PyObject
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython.ref cimport Py_INCREF, Py_DECREF


cdef int memsize_from_length(int length) nogil:
    return length * sizeof(PyObject *)


cdef class fastlist:
    def __cinit__(self, int length = 0):
        self._length = length
        self._array = <PyObject **>PyMem_Malloc(memsize_from_length(length))
        if self._array == NULL:
            raise MemoryError()
        cdef int i
        if length > 0:
            for i in range(length):
                Py_INCREF(None)
                self._array[i] = <PyObject *>None
    
    @staticmethod
    def from_sequence(seq):
        cdef fastlist result = fastlist(len(seq))
        cdef int i
        for i in range(len(seq)):
            Py_INCREF(seq[i])
            result._array[i] = <PyObject *>seq[i]
        return result

    def __dealloc__(self):
        cdef int i
        for i in range(self._length):
            Py_DECREF(<object>self._array[i])
            self._array[i] = NULL
        PyMem_Free(self._array)
    
    cdef object _cgetitem_int(self, int index):
        return <object>self._array[index]
    
    cdef object _cgetitem_slice(self, slice indices):
        cdef (int, int, int) dests = indices.indices(self._length)
        cdef fastlist result = fastlist((dests[1] - dests[0]) // dests[2])
        cdef int i = 0, j
        cdef PyObject* item
        for j in range(*dests):
            item = self._array[j]
            Py_INCREF(<object>item)
            result._array[i] = item
            i += 1
        return result
    
    def __getitem__(self, index):
        if isinstance(index, int):
            return self._cgetitem_int(index)
        elif isinstance(index, slice):
            return self._cgetitem_slice(index)
        raise TypeError('incompatible index type: ' + repr(index.__class__.__name__))
    
    def __len__(self):
        return self._length
    
    def __iter__(self):
        cdef int i
        for i in range(self._length):
            yield <object>self._array[i]
    
    def __repr__(self):
        return 'fastlist.from_sequence([%s])' % ', '.join(repr(v) for v in self)
    
    cdef void _csetitem_int(self, int index, object value):
        Py_INCREF(value)
        self._array[index] = <PyObject *>value

    cdef void _csetitem_slice(self, slice indices, object value):
        cdef (int, int, int) dests = indices.indices(self._length)
        cdef fastlist result = fastlist((dests[1] - dests[0]) // dests[2])
        cdef int i = 0, j
        cdef object item
        for j in range(*dests):
            item = value[j]
            Py_INCREF(item)
            self._array[i] = <PyObject *>item
            i += 1
    
    def __setitem__(self, index, object value):
        if isinstance(index, int):
            self._csetitem_int(index, value)
        elif isinstance(index, slice):
            self._csetitem_slice(index, value)
        else:
            raise TypeError('incompatible index type: ' + repr(index.__class__.__name__))
    
    def resize(self, int newlength):
        if newlength == self._length:
            return
        self._array = <PyObject **>PyMem_Realloc(self._array, memsize_from_length(newlength))
        if self._array == NULL:
            raise MemoryError()
        if newlength > self._length:
            for i in range(self._length, newlength):
                Py_INCREF(None)
                self._array[i] = <PyObject *>None
        self._length = newlength
