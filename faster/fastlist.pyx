# cython: profile=True

from cython cimport sizeof
from cpython cimport PyObject
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython.ref cimport Py_INCREF, Py_DECREF


cdef inline int memsize_from_length(int length) nogil:
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
    def from_sequence(object seq):
        return from_sequence(seq)

    @staticmethod
    def from_iterator(object it, int sizehint=0):
        return from_iterator(it, sizehint)

    def __dealloc__(self):
        cdef int i
        for i in range(self._length):
            Py_DECREF(<object>self._array[i])
        PyMem_Free(self._array)
    
    cdef object _cgetitem_int(self, int index):
        if index < 0 or index >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (index, self._length))
        return <object>self._array[index]
    
    cdef fastlist _cgetitem_slice(self, slice indices):
        cdef (int, int, int) dests = indices.indices(self._length)
        cdef fastlist result = fastlist((dests[1] - dests[0]) // dests[2])
        cdef int i = 0, j
        cdef PyObject* item
        for j from dests[0] <= j < dests[1] by dests[2]:
            if j < 0 or j >= self._length:
                raise IndexError('index %r out of range for fastlist of length %r' % (j, self._length))
            item = self._array[j]
            Py_INCREF(<object>item)
            result._array[i] = item
            i += 1
        return result
    
    def __getitem__(fastlist self, index):
        if isinstance(index, int):
            return self._cgetitem_int(index)
        elif isinstance(index, slice):
            return self._cgetitem_slice(index)
        raise TypeError('incompatible index type: ' + repr(index.__class__.__name__))
    
    def __len__(fastlist self):
        return self._length
    
    def __iter__(fastlist self):
        cdef int i
        for i in range(self._length):
            yield <object>self._array[i]
    
    def __repr__(fastlist self):
        return 'fastlist.from_sequence([%s])' % ', '.join(repr(v) for v in self)
    
    cdef void _csetitem_int(self, int index, object value) except *:
        if index < 0 or index >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (index, self._length))
        Py_INCREF(value)
        self._array[index] = <PyObject *>value

    cdef void _csetitem_slice(self, slice indices, object value) except *:
        cdef (int, int, int) dests = indices.indices(self._length)
        cdef fastlist result = fastlist((dests[1] - dests[0]) // dests[2])
        cdef int i = 0, j
        cdef object item
        for j from dests[0] <= j < dests[1] by dests[2]:
            if i < 0 or i >= self._length:
                raise IndexError('index %r out of range for fastlist of length %r' % (i, self._length))
            item = value[j]
            Py_INCREF(item)
            self._array[i] = <PyObject *>item
            i += 1
    
    def __setitem__(fastlist self, index, object value):
        if isinstance(index, int):
            self._csetitem_int(index, value)
        elif isinstance(index, slice):
            self._csetitem_slice(index, value)
        else:
            raise TypeError('incompatible index type: ' + repr(index.__class__.__name__))

    cdef void _cdelitem_int(self, int index):
        if index < 0 or index >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (index, self._length))
        Py_DECREF(<object>self._array[index])
        cdef int i
        for i in range(index + 1, self._length):
            self._array[i - 1] = self._array[i]
        self.resize(self._length - 1)

    cdef void _cdelitem_slice(self, slice indices):
        cdef (int, int, int) dests = indices.indices(self._length)
        cdef int offset = 0, i
        for i from dests[0] <= i < dests[1] by dests[2]:
            self._cdelitem_int(i - offset)
            offset += 1
    
    def __delitem__(fastlist self, index):
        if isinstance(index, int):
            self._cdelitem_int(index)
        elif isinstance(index, slice):
            self._cdelitem_slice(index)
        else:
            raise TypeError('incompatible index type: ' + repr(index.__class__.__name__))
    
    cpdef void resize(self, int newlength) except *:
        if newlength == self._length:
            return
        cdef int i
        if newlength < self._length:
            for i in range(newlength, self._length):
                Py_DECREF(<object>self._array[i])
        self._array = <PyObject **>PyMem_Realloc(self._array, memsize_from_length(newlength))
        if self._array == NULL:
            raise MemoryError()
        if newlength > self._length:
            for i in range(self._length, newlength):
                Py_INCREF(None)
                self._array[i] = <PyObject *>None
        self._length = newlength
    
    cpdef void append(self, object value) except *:
        self.resize(self._length + 1)
        Py_INCREF(value)
        self._array[self._length - 1] = <PyObject *>value
    
    def clear(self):
        self.resize(0)

    cpdef fastlist copy(self):
        cdef fastlist result = fastlist(self._length)
        cdef int i
        cdef PyObject* item
        for i in range(self._length):
            item = self._array[i]
            Py_INCREF(<object>item)
            result._array[i] = item
        return result
    
    cdef void _fast_extend(self, fastlist other) except *:
        cdef int templen = self._length
        cdef PyObject* item
        cdef int i
        self.resize(templen + other._length)
        for i in range(other._length):
            item = other._array[i]
            Py_INCREF(<object>item)
            self._array[i + templen] = item
    
    cpdef void extend(self, object other) except *:
        if isinstance(other, fastlist):
            self._fast_extend(other)
            return
        cdef int templen = self._length, otherlen = len(other)
        cdef object item
        cdef int i
        self.resize(templen + otherlen)
        for i in range(otherlen):
            item = other[i]
            Py_INCREF(item)
            self._array[i + templen] = <PyObject *>item
    
    def __add__(fastlist self, object other):
        cdef fastlist copied = self.copy()
        copied.extend(other)
        return copied

    # def __radd__(fastlist self, object other):
    #     cdef fastlist copied = self.copy()
    #     copied.extend(other)
    #     return copied
    
    def __iadd__(fastlist self, object other):
        self.extend(other)
        return self
    
    cdef void multiply(self, int times) except *:
        cdef int templen = self._length
        self.resize(templen * times)
        cdef int i, j
        cdef PyObject* item
        for i in range(templen):
            item = self._array[i]
            for j in range(times):
                Py_INCREF(<object>item)
                self._array[j * templen + i] = item
    
    def __mul__(fastlist self, int times):
        cdef fastlist result = self.copy()
        result.multiply(times)
        return result

    # def __rmul__(fastlist self, int times):
    #     cdef fastlist result = self.copy()
    #     result.multiply(times)
    #     return result
    
    def __imul__(fastlist self, int times):
        self.multiply(times)
        return self

    cpdef void insert(self, int i, object x) except *:
        if i < 0 or i > self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (i, self._length))
        elif i == self._length:
            self.append(x)
            return
        self.resize(self._length + 1)
        cdef int j
        for j in range(self._length - 1, i, -1):
            self._array[j] = self._array[j - 1]
        Py_INCREF(x)
        self._array[i] = <PyObject *>x

    cpdef object pop(self, int i):
        if i < 0 or i >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (i, self._length))
        cdef object item = <object>self._array[i]
        cdef int j
        for j in range(i, self._length - 1):
            self._array[i] = self._array[i + 1]
        self.resize(self._length - 1)
        return item
    
    cpdef void remove(self, object x, int starthint=0) except *:
        if starthint < 0 or starthint >= self._length:
            starthint = 0
        cdef int i
        for i in range(starthint, self._length):
            if x == <object>self._array[i]:
                self.pop(i)
                return
        if starthint > 0:
            for i in range(0, self._length):
                if x == <object>self._array[i]:
                    self.pop(i)
                    return
        raise ValueError('fastlist has no item %r' % x)
    
    cpdef void reverse_range(self, int start, int end) except *:
        if start < 0 or start >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (start, self._length))
        if end < 0 or end >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (end, self._length))
        cdef int i, j
        for i from start <= i < start + ((end - start + 1) // 2) by 1:
            j = start + end - i
            self._array[i], self._array[j] = self._array[j], self._array[i]
    
    cpdef void reverse(self):
        self.reverse_range(0, self._length - 1)

    cpdef int index(self, object x, int i=0, int j=-1) except -1:
        if j == -1:
            j = self._length
        if i < 0 or i >= self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (i, self._length))
        if j < 0 or j > self._length:
            raise IndexError('index %r out of range for fastlist of length %r' % (j, self._length))
        cdef int current
        cdef object obj
        for current in range(i, j):
            obj = <object>self._array[current]
            if obj == x:
                return current
        raise ValueError('%r not in fastlist of length %r' % (x, self._length))

    cpdef int count(self, object x):
        cdef int i, res = 0
        cdef object obj
        for i in range(self._length):
            obj = <object>self._array[i]
            if obj == x:
                res += 1
        return res


cdef fastlist from_sequence(object seq):
    cdef fastlist result = fastlist(len(seq))
    cdef int i
    for i in range(len(seq)):
        Py_INCREF(seq[i])
        result._array[i] = <PyObject *>seq[i]
    return result


cdef fastlist from_iterator(object it, int sizehint):
    cdef fastlist result = fastlist(sizehint)
    cdef int i = 0
    for x in it:
        Py_INCREF(x)
        if i >= result._length:
            result.resize(i + 1)
        result._array[i] = <PyObject *>x
        i += 1
    if i + 1 < result._length:
        result.resize(i + 1)
    return result


import collections.abc
collections.abc.Sequence.register(fastlist)
