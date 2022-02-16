There are many essay about minimal CPU and so on, this is more one.

Define a CPU with only 4 registers and a program counter. A work register (W), a hold register (N), a address register (A) and a operation register (T). 

For this model the op-codes are:

  | op code | bits | operation | does |
  | :----: | :----: | :----: | :----: |
  | nop | 0 0 0 0 | W -> W | move contents of W to W |
  | mov w, t | 0 0 0 1 | T -> W | move contents of T to W |
  | mov w, n | 0 0 1 0 | W -> W | move contents of N to W |
  | ld w, [a] | 0 0 1 1 | [A] -> W | move contents of [A] to W |
  | mov a, w | 0 1 0 0 | W -> A | move contents of W to W |
  | mov t, w | 0 1 0 1 | T -> T | move contents of T to W |
  | mov n, n | 0 1 1 0 | W -> N | move contents of N to W |
  | st [a], w | 0 1 1 1 | W -> [A] | move contents of [A] to W |
