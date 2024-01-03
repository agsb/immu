# The Stacks

_this is still a stub_

_Charles Moore says 22 levels is enough for Forth._

## Back Stacks

The 6502 have two peculiar pages, the zero page and stack page, both unique and with 256 bytes. All sub-routines calls (JSR) and returns (RTS) uses the stack page for 16-bit pointers, also the indirect indexed and indexed indirect modes uses page zero. Those are valuable resources.

An good revew of 6502 addressing modes at [emulators](http://www.emulator101.com/6502-addressing-modes.html).

In 6502 code, to pass a byte between memory, always need use LDA and STA, there are exotic alternatives, but all uses the accumulator.

Almost 6502 typical stack implementations does as standart: 
      
      1. Allow till 128 words deep stack; 
      2. Any operation with values at stack must do pushs and pulls. 
      3. Any multitask or multiuser system must split or copy the stack.
      4. Stack of 128 words are round-robin, else could need check limits.
      
If using page zero or stack page, the 128 words must be split in 3 parts: One for generic code use ( < 84 words ); One for data stack ( > 22 words ); One for return stack ( > 22 words ). For multitask or multiuser, could be 2 tasks with 2 stacks of 24 words and a generic stack of 32.
      
These are most commom, using idz, ptz, lsb, msb in zero page: 

### hardware stack SP

      .macro push_sp idz, lsb, msb 
            LDA \idz; TSX; STX \idz; TAX; TXS;      
            LDA \lsb; PHA; LDA \msb; PHA;          
            LDA \idz; TSX; STX \idz; TAX; TXS;      
      .endmacro ; 
      
      .macro pull_sp idz, lsb, msb
            LDA \idz; TSX; STX \idz; TAX; TXS;     
            PLA; STA \msb; PLA; STA \lsb;           
            LDA \idz; TSX; STX \idz; TAX; TXS;     
      .endmacro ;  

Uses the hardware stack, must split. Each stack uses cycles ~66 cc, 40 bytes of code and 4 bytes. _Could not use JSR/RTS inside_.

### page zero indexed by X
      
      .macro push_zx idz, ptz, lsb, msb 
            LDX \idz; DEX; LDA \msb; STA \ptz, X; DEX; LDA \lsb; STA \ptz, X; STX \idz;
      .endmacro     
      
      .macro pull_zx idz, ptz, lsb, msb 
            LDX \idz; LDA \ptz, X; STA \msb; INX; LDA \ptz, X; STA \lsb; INX; STX \idz;
      .endmacro

Uses the page zero as stack, must be split. Each stack uses cycles ~48 cc, 28 bytes of code and 4 bytes at zero page;

### page zero indirect indexed by Y

      .macro push_iy idz, ptz, lsb, msb 
            LDY \idz; DEY; LDA \msb; STA (\ptz), Y; DEY; LDA \lsb; STA (\ptz), Y; STY \idz; 
      .endmacro      
      
      .macro pull_iy idz, ptz, lsb, msb 
            LDY \idz; LDA (\ptz), Y; STA \msb; INY; LDA (\ptz), Y; STA \lsb; INY; STY \idz; 
      .endmacro

Uses the a pointer in page zero to anywhere in memory. Stacks with up to 128 cells. Each stack uses ~50 cc, 28 bytes of code and 4 bytes at zero page. _Multiuser and Multitask systems can change the pointers anytime._ 

### absolute address indexed by X or Y
      
      .macro push_ax idz, lsb, msb 
            LDX \idz; LDA \msb; STA ptr - 1, X; LDA \lsb; STA ptr - 2, X; DEX; DEX; STX \idz; 
      .endmacro    
      
      .macro pull_ax idz, lsb, msb 
            LDX \idz; LDA ptr + 0, X; STA \lsb; LDA ptr + 1, X; STA \msb; INX; INX; STX \idz; 
      .endmacro

Uses one absolute pointer _ptr_ to memory. Stacks with up to 128 cells. Each stack uses ~52 cc, 32 bytes of code and 2 bytes at zero page. _Any operation with values at stack could be at direct offset, no need use pulls and pushs_

### split absolute address indexed by X or Y
      
      .macro push_axs idz, lsb, msb 
            LDX \idz; LDA \msb; STA ptr_lo - 1, X; LDA \lsb; STA ptr_hi - 1, X; DEX; STX \idz;
      .endmacro    
      
      .macro pull_axs idz, lsb, msb 
            LDY \idz; LDA ptr_lo + 0, X; STA \lsb; LDA ptr_hi + 0, X; STA \msb; INX; STX \idz;
      .endmacro

Uses two absolute pointers _ptr_lo_ and _ptr_hi_ to memory. Stacks with up to 256 cells, splited in two parts. Each stack uses ~48 cc, 30 bytes of code and 2 bytes at zero page.  _Any operations with values at stack could be at direct offset, no need pulls and pushs_

### direct address with indirect access by Y

      .macro push_di ptr, lsb, msb 
            LDY #0; 
            LDA \msb; STA (ptr), Y; 
            INC ptr + 0; BNE :+ ; INC ptr + 1; : ;
            LDA \lsb; STA (ptr), Y; 
            INC ptr + 0; BNE :+ ; INC ptr + 1; : ;
       .endmacro    
      
      .macro pull_di ptr, lsb, msb 
            LDY #0; 
            LDA ptr + 0; BNE :+ ; DEC ptr + 1; : DEC ptr + 0; 
            LDA (ptr), Y; STA \msb; 
            LDA ptr + 0; BNE :+ ; DEC ptr + 1; : DEC ptr + 0; 
            LDA (ptr), Y; STA \lsb;
      .endmacro

Uses an absolute pointer _ptr_ to memory. _Stacks with up to any size_. Each stack uses ~96 cc, 58 bytes of code and 2 bytes at page zero. 

### Comparasion

| type | code size | cycles | cells  | notes |
| -- | -- | -- | -- | -- | 
| hardware stack SP | 40 | 66 | 128 | must split*, must use push and pull | 
| page zero indexed by X | 28 | 48 | 128 | must split*, must use push and pull |
| indirect indexed by Y | 28 | 50 | 128 | must split*, must use push and pull |
| absolute address indexed | 32 | 52 | 128 | any operation at direct offset, no need pull and push |
| split absolute addres indexed | 30 | 48 | 256 | any operation at direct offset, no need pull and push |
| direct address with indirect access | 58 | 96 | any size | must use push and pull | 

\* a least 22 cells of each stack and rest for inline code
  
### What Do 

Consider for no multitask, no multiuser, just 128 deep stacks, reduce overhead, direct memoy access and good timing, then

_Using absolute address indexed access for stacks_ 

It provides the most fast overall implementation because does not need use push and pull. 

All operations DROP, DUP, OVER, SWAP, ROT, AND, OR, XOR, NEG, INV, ADD, SUB, INC, DEC, EQ, LT, GT, SHL, SHR, AT (Fetch), TO (Store), are done using offsets (table 2).
  
  | _table 2_ | memory layout|
  | --- | --- | 
  | low | address |
  | -4  | LSB *COS*|
  | -3  | MSB |
  | -2  | LSB *BOS*|
  | -1  | MSB |
  |  0  | LSB **TOS** |
  | +1  | MSB |
  | +2  | LSB *NOS* |
  | +3  | MSB |
  | +4  | LSB *MOS* |
  | +5  | MSB |
  | +6  | LSB *POS* |
  | +7  | MSB |
  | high | address |

      - Odd address are always MSB, even address are always LSB
      - TOS, top in stack; NOS, next in stack; 
      - MOS, POS, next in sequence, BOS, COS back in sequence, for easy macros 

### Best

**For common "alone" applications _zero page indexed by X_ with 24 words per stack and 32 words shared could be faster.** 

Note that all modes needs read and write stack indexes from/into somewhere, then _lda, sta, inc, dec_ are always used.

     
     
