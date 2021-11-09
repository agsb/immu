# No Spoon

_"there is no spoon", Matrix, https://www.youtube.com/watch?v=uAXtO5dMqEI_

(in progress)

Immu Forth will be for RiscV processors, that have single fundaments: 
  
  1. All memory in a continuous address;
  2. All memory is accessed in bytes;
  3. Any registers could load from and store into main memory; 
  4. There is no stack.
    
Better, there are a group of registers that must be saved before used, "callee" as in ISA specifications, https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf> by RTFM.

Any register could be used as stack, and Forth uses a instruction pointer, a return stack, a parameter stack, and three for operations, maybe more two for temporary hold values.

As common sense, never use processor stack pointer as parameter stack.

_"Organization And Design the hadware/software interface", David P. Patterson, John H. Hennessy, 2005, 3th Edition_

1. **Simplicity favors regularity.** 
2. **Smaller is faster.** 
3. **Make the common case fast.** 
4. **Good design demands good compromises.** 

