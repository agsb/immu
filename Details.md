# An immutable Forth

 An implementation of Forth with inner interpreter using **minimal indirect thread code** and a dictionary made of machine independent vocabularies. 
  
 Only the inner interpreter and vocabularies related to systems, drives and primitives are machine dependent. 
  
## the inner interpreter
  
  _“ : NEXT IP )+ W MOV W )+ ) JMP ; Now Forth was complete. And I knew it.”, Charles H. Moore, “Forth - The Early Years”_
  
The inner interpreter is Forth's heartbeat.

It casts virtual machine magic by translating coded sequences into algorithms that transform the information.

These encoded sequences are preserved in a dictionary as words, made up of name and code tuples.

## the dictionary

The dictionary is a table, with a linked list of vocabularies, with linked lists of words, where words are tuples, made up of 

  - a word header, [link][size+flags][name][pad?]

  - a word definition, [ _code-word_ ][parameters][ _last-word_ ]

Ideally, there are only two types of words,

  - Compounds, _that contains only references of words_ , and

  - Primitives, _that contains only machine code without calls_ .

Usually

  - _code-word_ : is NEST (DOCOLON) for compound or DOCODE for primitives
    
  - _last-word_ : is UNNEST (SEMIS) for compound or EXIT for primitives

  - parameters : is a list of references or a sequence of machine code

## the classic indirect thread code

```
classic format

defword:  ; a NEST and a UNNEST in all compound words
+------+---+---+---+---+---+---+---+---+------+------+-------+--------+
| LINK | 6 | D | O | U | B | L | E | 0 | NEST | DUP  | PLUS  | UNNEST |
+------+---+---+---+---+---+---+---+---+------+------+-------+--------+

defcode:  ; a self reference and a EXIT (macro NEXT) in all primitives
+------+---+---+---+---+---------+-self--+-------+-------+------+
| LINK | 3 | D | U | P | to self | code  | code  | code  | EXIT |
+------+---+---+---+---+---------+-------+-------+-------+------+
```

The operations of a **classic indirect thread code** inner interpreter, in non optimized pseudo code, are :

```
NEXT: 
  Fetch the address pointed by IP onto WR
  Increment IP by address size 
  Jump to WR

NEST: (aka ENTER, DOCOLON, at start of words)
  Push IP onto call stack
  Set IP to point to the first address of the called routine
  Execute NEXT

UNNEST: (aka EXIT, SEMIS, at end of words)
  Pull IP from call stack
  Execute NEXT

EXIT: ( at end of code )
  Execute NEXT
```

All compound words, does two jumps and a call with return.

All primitive words does three jumps.

Also in optimized codes, NEXT is executed two times, and is placed between UNNEST and NEST.

the IP register must be preserved between calls.

## A proposal for **minimal indirect thread code**   

_"Forth is free to reinvent the wheel, and I think that is a marvelous concept. No one should ever be afraid to reinvent the wheel, and we do it every day.", Chuck Moore, https://www.youtube.com/watch?v=xoyDNIcnpgc&t=9051s_

```
proposed format

defword:  ; only a ENDS,
+-------+---+---+---+---+---+---+---+---+-----+------+------+
| LINK  | 6 | D | O | U | B | L | E | 0 | DUP | PLUS | ENDS |    
+-------+---+---+---+---+---+---+---+---+-----+------+------+
       
defcode:  ; a NULL and a jump link:
+-------+---+---+---+---+------+------+------+------+------------+
| LINK  | 3 | D | U | P | NULL | code | code | code | jump link: |
+-------+---+---+---+---+------+------+-------+-----+------------+
```

The operations of a **minimal indirect thread code** inner interpreter, in non optimized pseudo code, are :

```
NEXT: 
  Fetch the address pointed by IP onto WR  
  Increment IP by address size
  if WR is NULL, then Execute JUMP
  else Execute NEST

NEST: 
  Push IP onto call stack
  Copy WR to IP
  Execute NEXT

UNNEST: 
  Pull IP from call stack
  Execute NEXT

JUMP:
  Pull WR from call stack
  Jump to address in IP

LINK:
  Copy WR to IP
  Execute NEXT
  
```

**_"Explain all that", said the Mock Turtle.“, Lewis Carol, "Alice's Adventures in Wonderland"_**

The code above only executes jumps when references to primitives words, marked with a NULL reference.

All composite word references are directly, placed and removed, onto the return stack, do not executing any jump.

Uses jump and link, as modern RISC-V processors does.

Does just a compare per Forth word, to decide if executes a NEST or a JUMP.

The pointer IP do not need be preserved. The pointer WR, as link register, must be reserved.

## More with less 

_"An interpreter can be reduced to a switch-case structure contained within a loop.", Ken Boak, <https://github.com/monsonite/MINT>_

Also, JUMP could be extended, with pseudo op-codes as Token Threaded Code (TTC), for more “inner functions”, as a inline lookup table:

```
if WR greater than LAST_VM_CODE, then Execute NEST
else 
Increment IP by address size, 
case WR of
  0x00    jump to IP, 
  0x01    jump to IP+(IP), aka (do_does, or tail recursion)
  0x02    push IP onto data stack, aka (do_variable)
  0x03    push (IP) onto data stack, aka (do_constant)
  etc.    All Executes as "inline", no calls
Execute Link
```

## the New Dictionary

A Dictionary with vocabularies that could be:
  
    processor independent (for all with compounds words)
  
    processor dependent (for systems, drivers, primitives) 
  
In _independent vocabularies_ :
    
    only headers and references, no code inside,
    
    full (ihex) portable and relocatable and extensible,
    
    allow sharing of pre-compiled vocabularies,

In _dependent vocabularies_ :
    
    just routines coded for specific environments,
    
    adaptable development for diverse situations.    
    
## What more ? 

    How to:
        
        Import and export compiled vocabularies ? Text well know format, ihex.
        
        Verify the integrity of shared vocabularies ? Complex hashs, SHA256. 
        
        Verify the authenticity of shared vocabularies ? Digital signatures, PGP keys.
  
        Relocate the references within vocabularies ? Position independent code
        
        Manage the linked vocabularies ? Ma(i)stery Linked Lists.

        Split dictionary for Code and Headers. As older Forths.
        
## Conclusion

I see Forth as a model of the RNA-DNA type. The inner interpreter acts as RNA and vocabularies acts as DNA. 

It consumes information and produces transformations. The primitives words act as extended ACTUG proteines.

Some information produces recipes, sequences of algorithms encoded by references to routines, that change the information. Like real protein sequences.

And it can grow, incorporating these recipes and maybe, perhaps, creating recipes as well.

The proposed small change for **extended indirect thread code** allows these compiled recipes to be shared as executables inside Forth virtual machines.

## **and that could be an immu( )table Forth.**

```
/* 
basic RISCV, Using R32I, 32 bits cell,

Minimal Indirect Thread Code
s5, RP, return stack, grows downwards
s6, IP, aka instruction pointer
s9, Wr, aka link pointer
zero, is always zero

header is a macro, does the Forth dictionary header

all compound words ends with a reference to ENDS

all primitive words ends with jump _link 

*/

header "ENDS","ends"
    .word 0x0    
_unnest: ; pull
    lw s6, 0(s5)
    addi s5, s5, CELL
    ; jal zero, _next
    
_next: ; cast
    lw s9, 0 (s6)
    addi s6, s6, CELL

    beq s9, zero, _jump
    ; jal zero _nest
    
_nest: ; push  
    addi s5, s5, -1*CELL
    sw s6, 0(s5)

_link: ; link
    add s6, s9, zero
    jal zero, _next
    
_jump:  ; jump
    lw s6, 0(s5)
    addi s5, s5, CELL
    jalr zero, s9, 0

```  


## bibliography 
      
http://worrydream.com/refs/Moore%20-%20Forth%20-%20The%20Early%20Years.pdf

http://www.forth.org/POL.pdf

http://thinking-forth.sourceforge.net/

http://www.forth.org/KittPeakForthPrimer.pdf

http://www.forth.org/fig-forth/fig-forth_PDP-11.pdf

http://forth.org/OffeteStore/1013_eForthAndZen.pdf

https://www.bradrodriguez.com/papers/moving1.htm

https://muforth.nimblemachines.com/threaded-code/

https://muforth.nimblemachines.com/call-versus-branch-and-link/

https://github.com/cesarblum/sectorforth

https://github.com/theandrew168/derzforth

https://riscv.org/specifications/

## Disclaimer

/*
 *  DISCLAIMER"
 *
 *  Copyright © 2020, Alvaro Gomes Sobral Barcellos,
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions"
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *
 */

      

