from cython cimport sizeof
from cpython cimport PyObject
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython.ref cimport Py_INCREF, Py_DECREF


cdef class fastlist:
    def __cinit__(self, int length = 0):
        self._length = length
        self._array = <PyObject **>PyMem_Malloc(length * sizeof(PyObject *))
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
    
    def __getitem__(self, int index):
        return <object>self._array[index]
    
    def __len__(self):
        return self._length
    
    def __iter__(self):
        cdef int i
        for i in range(self._length):
            yield <object>self._array[i]
    
    def __repr__(self):
        return 'fastlist.from_sequence([%s])' % ', '.join(repr(v) for v in self)
    
    def __setitem__(self, int index, object value):
        Py_INCREF(value)
        self._array[index] = <PyObject *>value
