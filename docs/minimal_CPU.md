There are many essay about minimal CPU and so on, this is more one.

Define a CPU with only 4 registers and a program counter. A work register (W), a hold register (N), a address register (A) and a operation register (T). 

For this model the op-codes are:

  | op code | bits | operation | does |
  | :----: | :----: | :----: | :----: |
  | nop | 0 0 0 0 | W -> W | move contents of W to W |
  | mov w, t | 0 0 0 1 | T -> W | move contents of T to W |
  | mov w, n | 0 0 1 0 | W -> W | move contents of N to W |
  | load | 0 0 1 1 | [A] -> W | move contents of [A] to W |
  | mov a, w | 0 1 0 0 | W -> A | move contents of W to A |
  | mov t, w | 0 1 0 1 | T -> T | move contents of T to W |
  | mov n, n | 0 1 1 0 | W -> N | move contents of N to W |
  | store | 0 1 1 1 | W -> [A] | move contents of [A] to W |
  | tst | 1 0 0 0 | test T equal 0 | move contents of W to A |
  | inc | 1 0 0 1 | T = T + 1 | increments T by one |
  | dec | 1 0 1 0 | T = T - 1 | decrements T by one |
  | clr | 1 0 1 1 | T = 0 | clear T|
  | nand | 1 1 0 0 | T - T nand W | nand T . W |
  | sum | 1 1 0 1 | T = T + W | increments T by W |
  | shft | 1 1 1 0 | T = T - 1 | shift right T |
  | jmp | 1 1 1 1 | jump | jump  | 
  
  
  