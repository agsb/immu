# About eForth

(this file is a stub)

_"For a hundred years, Zen was passed from mouth to mouth, and from heart to heart."_

## Greetings to eForth

based in "eForth and Zen" by Dr. C. H. Ting, Ofeete Enterprises, 2013

Code for a CPU 8086 and a old PC-MSDOS system.

## What I like

  - use of interrupt 021H interface of DOS.
  - a concise set of primitives (code) and compound (colon) words;
  - code and name separated dictionaries, "This arrangement has the advantage that the name dictionary can be
eliminated from a target system which does not use an interpreter.";
  - use of pointer to basic routines 'QKEY, 'EMIT, 'EXPECT, 'ECHO, 'PROMPT, 'EVAL, 'NUMBER, 'TAP;
  - use a common user area for forth variables and variables that return pointers inside that area;
  - that user area variables are referenced by offsets;
  - use of vocabularies with current, context and a list for vocabularies;
  - use of serial classic interface, Universal Synchronous Asynchronous Receiver Transmitter (USART);
  - use of FOR NEXT instead of DO LOOP (+LOOP -LOOP ...)
  - no multi-task but expect a round-robin linked list at top of user area;

## What I do not 

  - direct thread code;
  - direct address branch, absolute instead of relative;
  - use o 'CALL doLIST' at begin of "colon words" and ends with 'magic' EXIT;
  - share TIB and return stack;
  - where is the DOS/SO stack ? Somewhere inside 0-100H;
  - a small, and fixed size, list for vocabularies;
  - only <0 as primitive;
  - FOR counts to <0;
  - No TOS, NOS or TOR, primitives using stacks must ever pop ('POP BX')
  - No CREATE DOES> DEFER IS VALUE TO ASSIGN :NONAME 
##

