
# An immutable Forth

  An implementation of Forth with a extended inner interpreter and a dictionary made up of machine independent vocabularies. 
  
  Only the inner interpreter and vocabularies related to systems, drives and primitives are machine dependent. 
  
## the inner interpreter
  
  _“ : NEXT IP )+ W MOV W )+ ) JMP ; Now Forth was complete. And I knew it.”, Charles H. Moore, “Forth - The Early Years”_
  
The inner interpreter is Forth's heartbeat.

It makes virtual machine magic happen by translating coded sequences into algorithms that transform information.

These sequences are preserved in a dictionary as words and code.

## the dictionary

The dictionary is a table, with a linked list of vocabularies, with linked lists of words, where words are made up of 

  - a Word header, [link][size+flags][name][pad?]

  - a Word definition, [ _code-word_ ][parameters][ _last-word_ ]

Ideally, there are only two types of words,

  - Compounds, _that contains only* references of words_ , and

  - Primitives, _that contains only machine code without calls_ .

_code-word_ : DOCOLON for compound or DOCODE for primitives
    
_last-word_ : SEMIS for compound or EXIT for primitives

parameters: could be a list of references or code

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
------+---+---+---+---+----------+-------+-------+-------+------+
```

The operations of a classic indirect thread code inner interpreter, in non optimized pseudo code, are :

```
NEXT: 
  Fetch the address pointed by IP onto WR
  Increment IP by address size
  Jump to WR

NEST: (aka DOCOLON, at start of words)
  Push IP onto call stack
  Set IP to point to the first address of the called routine
  Execute NEXT

UNNEST: (aka SEMMIS, at end of words)
  Pull IP from call stack
  Execute NEXT

EXIT: ( at end of code )
  Execute NEXT
```
Note that all compound words, does two jumps and a call with return, and primitive words does three jumps.

Also NEXT is executed two times, because in optmized codes, it is placed just bellow NEST and used by UNNEST.

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

NEST: (aka DOCOLON)
  Push IP onto call stack
  Copy WR to IP
  Execute NEXT

UNNEST: (aka SEMMIS)
  Pull IP from call stack
  Execute NEXT

JUMP:  
  Copy IP to WR
  Increment IP by address size
  Jump to fetched address in WR

LINK: (aka EXIT )
  Execute NEXT

```
## Explain 

_"Explain all that", said the Mock Turtle. “Alice's Adventures in Wonderland”, Lewis Carrol*_

The code above executes only references to primitives words.

All composite word references are directly placed and removed, onto the return stack.

Uses jump and link, as call model,

and just make one more comparison.

## More with less 

Also, could JUMP be extended, with use of pseudo op-codes for more “inner functions” as a inline lookup table:

```
if WR greather than LAST_VM_CODE, then Execute NEST
else Increment IP by address size, 
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
    
    full (hex) portable and relocatable and extensible,
    
    allow sharing of pre-compiled vocabularies,

In _dependent vocabularies_ :
    
    just routines coded for specific environments,
    
    adaptable development for diverse situations.    

## Conclusion

I see Forth as a model of the RNA-DNA type. The inner interpreter acts as RNA and dictionaries act as DNA. It consumes information and produces transformations. The primitives words act as the AGCT proteines.

Some information produces recipes, sequences of algorithms encoded by references to routines, that change the information. Like real protein sequences.

And it can grow, incorporating these recipes and maybe, pherhaps, creating others as well.

The proposed small change allows these compiled recipes to be shared as executables.

*and that could be an immu table Forth.*
      
## bibliography 
      
“http://worrydream.com/refs/Moore - Forth - The Early Years.pdf”

“http://www.forth.org/POL.pdf”

“http://thinking-forth.sourceforge.net/”

“http://www.forth.org/KittPeakForthPrimer.pdf”

“http://www.forth.org/fig-forth/fig-forth_PDP-11.pdf”

“https://muforth.nimblemachines.com/threaded-code/”

“https://muforth.nimblemachines.com/call-versus-branch-and-link/”

“https://riscv.org/specifications/”

## Disclaimer


      

