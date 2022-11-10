minimal_CPU.md

# Abstract

There are many essays about minimum CPU, this is one more.

Define a CPU with 6 latch registers, for simplicity, all registers have the same number of bits as memory addresses;

The four operational registers are: a work register (W), a hold register (N), a memory address register (A), and an operation register (T).

The two special registers are: a program counter  (P), it points to a memory address, after  readed, is incremented automatically, and a condition register (C) that holds flags from specific operations and is read only.  

For this model the op-codes are:

  | op code | bits | operation | does |
  | :----: | :----: | :----: | :----: |
  0| nop | 0 0 0 0 | W -> W | move contents of W to W |
  1| mov w, t | 0 0 0 1 | T -> W | move contents of T to W |
  2| mov w, n | 0 0 1 0 | N -> W | move contents of N to W |
  3| load | 0 0 1 1 | [A] -> W | move from [A] into W |
  4| mov a, w | 0 1 0 0 | W -> A | move contents of W to A |
  5| mov t, w | 0 1 0 1 | W -> T | move contents of W to T |
  6| mov n, w | 0 1 1 0 | W -> N | move contents of W to N |
  7| store | 0 1 1 1 | W -> [A] | move from W into [A] |
  8| tst | 1 0 0 0 | test T equal 0 | if T is zero, jump to follow address else skip |
  9| inc | 1 0 0 1 | T = T + 1 | increments T by one |
  10| dec | 1 0 1 0 | T = T - 1 | decrements T by one |
  11| clr | 1 0 1 1 | T = 0 | clear T | 
  12| nand | 1 1 0 0 | T nand W | nand T . W |
  13| sum | 1 1 0 1 | T = T + W | increments T by W |
  14| shft | 1 1 1 0 | T = T >> 1 | shift right T >> 1 |
  15| jmp | 1 1 1 1 | jump | jump to follow address | 
  16| | | | | 
  
PS.
  
  Only test and jump instructions can changes the value of  the program counter.
  
  The CPU has just four states, wait, read, write, execute.

Updates:

  Must re-think opcodes to attend:
  
  How load a value in A register ? that opcodes rely in repeat W++, W->A, not useful. ( att. Duane Sand note in fb, thanks)
  
  How jump to a address at register ? 
  
# 07/11/2022

    change "inc" for "lit", move contents of next address to A
    change "tst" for if T is zero, jump to follow address else skip


