# No Spoon

_"there is no spoon", Maxtrix, https://www.youtube.com/watch?v=uAXtO5dMqEI_

This Forth will be for RiscV processors, that have single fundaments: 
  
  1. All registers could load from and store into main memory; 
  2. All memory in a continuous address;
  3. All memory is accessed in bytes;
  4. There is no stack.
    
Then any register could be used as stack, better, there are a group of registers that must be saved before used, "callee" as in ISA specifications, https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf> by RTFM.

Forth uses a instruction pointer, a return stack, a parameter stack, and three for operations, maybe more two for temporary hold values.
As common sense, never use processor stack pointer as parameter stack.

    


