import sys, os
from faster.fastlist import fastlist
import cProfile
from pstats import SortKey

l = fastlist.from_sequence(list(range(10)))
l.insert(0, 4)
print(l)
print(l.count(5))
print(l)
del l


# mult = 2 ** 24
# length = 15
# print('mult:', mult)
# print('size:', mult * length)


# print('\nfastlist:')
# cProfile.runctx('l *= m', {'l': fastlist.from_sequence(list(range(length))), 'm': mult}, {})

# print('\nlist:')
# cProfile.runctx('l *= m', {'l': list(range(15)), 'm': mult}, {})


print('no segfault')
