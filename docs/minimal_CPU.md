minimal_CPU.md

# Abstract

There are many essays about minimum CPU, this is one more.

Define a CPU with 6 latch registers, for simplicity, all registers have the same number of bits as memory addresses;

The four operational registers are: a work register (W), a hold register (N), a memory address register (A), and an operation register (T).

The two special registers are: a program counter  (P), it points to a memory address, after  readed, is incremented automatically, and a condition register (C) that holds flags from specific operations and is read only.  

For this model the op-codes are:

  | op code | bits | operation | does |
  | :----: | :----: | :----: | :----: |
  | nop | 0 0 0 0 | W -> W | move contents of W to W |
  | mov w, t | 0 0 0 1 | T -> W | move contents of T to W |
  | mov w, n | 0 0 1 0 | N -> W | move contents of N to W |
  | load | 0 0 1 1 | [A] -> W | move from [A] into W |
  | mov a, w | 0 1 0 0 | W -> A | move contents of W to A |
  | mov t, w | 0 1 0 1 | W -> T | move contents of T to W |
  | mov n, n | 0 1 1 0 | W -> N | move contents of N to W |
  | store | 0 1 1 1 | W -> [A] | move from W into [A] |
  | tst | 1 0 0 0 | test T equal 0 | if T is not zero, jump to follow address |
  | inc | 1 0 0 1 | T = T + 1 | increments T by one |
  | dec | 1 0 1 0 | T = T - 1 | decrements T by one |
  | clr | 1 0 1 1 | T = 0 | clear T | 
  | nand | 1 1 0 0 | T nand W | nand T . W |
  | sum | 1 1 0 1 | T = T + W | increments T by W |
  | shft | 1 1 1 0 | T = T >> 1 | shift right T >> 1 |
  | jmp | 1 1 1 1 | jump | jump to follow address | 
  | | | | | 
  
PS.
  
  Only test and jump instructions can changes the value of  the program counter.
  
  The CPU has just four states, wait, read, write, execute.

  
  
