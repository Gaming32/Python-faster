from faster.fastlist import fastlist


l = fastlist.from_sequence(list(range(10)))
l[3] = 'hello'
print(l)
del l
