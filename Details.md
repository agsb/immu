# An immutable Forth

 An implementation of Forth with inner interpreter using extended indirect thread code and a dictionary made of machine independent vocabularies. 
  
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

The operations of a classic indirect thread code inner interpreter, in non optimized pseudo code, are :

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

## A proposal for extended indirect thread code   

```
proposed format

defword:  ; only a UNNEST, (where did NEST go ?)
+-------+---+---+---+---+---+---+---+---+-----+------+---------+
| LINK  | 6 | D | O | U | B | L | E | 0 | DUP | PLUS | UNNEST  |    
+-------+---+---+---+---+---+---+---+---+-----+------+---------+
       
defcode:  ; a NULL and a jump, (where did self reference go ?)
+-------+---+---+---+---+------+------+------+------+-----------+
| LINK  | 3 | D | U | P | NULL | code | code | code | jump link |
+-------+---+---+---+---+------+------+-------+-----+-----------+
```

The operations of a extended indirect thread code inner interpreter, in non optimized pseudo code, are :

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
  Copy IP to WR
  Increment IP by address size
  Jump to fetched address in WR

LINK: 
  Execute NEXT

```

_"Explain all that", said the Mock Turtle. “Alice's Adventures in Wonderland”, Lewis Carrol*_

The code above only executes jumps when references to primitives words.

All composite word references are directly, placed and removed, onto the return stack, do not executing any jump.

Uses jump and link, as call model, as modern RISC-V processors does.

Does just a compare per Forth word, to decide if executes a NEST or a JUMP.

## More with less 

_"An interpreter can be reduced to a switch-case structure contained within a loop."_ , Ken Boak, <https://github.com/monsonite/MINT>, 05/11/2021

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
        
        Import and export compiled vocabularies ? text well know format, ihex.
        
        Verify the integrity of shared vocabularies ? complex hashs, sha256. 
        
        Verify the authenticity of shared vocabularies ? signatures, PGP keys.
  
        Relocate the references within vocabularies ? position independent code ?
        
        Manage the linked vocabularies ?

## Conclusion

I see Forth as a model of the RNA-DNA type. The inner interpreter acts as RNA and dictionaries act as DNA. 

It consumes information and produces transformations. The primitives words act as the ACTGU proteines.

Some information produces recipes, sequences of algorithms encoded by references to routines, that change the information. Like real protein sequences.

And it can grow, incorporating these recipes and maybe, perhaps, creating recipes as well.

The proposed small change allows these compiled recipes to be shared as executables inside Forth virtual machines.



## *and that could be an immu( )table Forth.*

```
/* 
basic RISCV, Using R32I, 32 bits cell,
Extended Indirect Thread Code
s5, return stack, grows downwards
s6, next reference, aka instruction pointer
s9, Wrk, temporary, not preserve
zero, is always zero

s6 must always points to a reference to be used by _next,
   and could be intentionally changed

header is a macro, does the Forth dictionary header

EXIT reference, ends all compound words, also is a primitive word;

jump (jal zero,) _link, ends all primitive words, also is a "hook" for debug before jump _next;

*/

header "EXIT","EXIT"
    .word 0x0
_unnest: // pull
    lw s6, 0(s5)
    addi s5, s5, 4
_next: // cast
    lw s9, 0 (s6)
    addi s6, s6, 4
 _void:
    beq s9, zero, _jump
_nest: // push  
    addi s5, s5, -4
    sw s6, 0(s5)
    add s6, s9, zero
_link:  // link  
    jal zero, _next
_jump:  // jump
    add s9, s6, zero
    addi s6, s6, 4
    jalr zero, s9, 0

```  


## bibliography 
      
“http://worrydream.com/refs/Moore - Forth - The Early Years.pdf”

“http://www.forth.org/POL.pdf”

“http://thinking-forth.sourceforge.net/”

“http://www.forth.org/KittPeakForthPrimer.pdf”

“http://www.forth.org/fig-forth/fig-forth_PDP-11.pdf”

"http://forth.org/OffeteStore/1013_eForthAndZen.pdf"

"https://www.bradrodriguez.com/papers/moving1.htm"

“https://muforth.nimblemachines.com/threaded-code/”

“https://muforth.nimblemachines.com/call-versus-branch-and-link/”

“https://riscv.org/specifications/”

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

      

