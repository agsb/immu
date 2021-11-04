/*
 *  DISCLAIMER
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
 *  NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *
 *  //-\--/\-//-\/-/\\\\/-\--\\\-///\-/-/\/--/\\\\/-\-//-/\//-/\//--//-///--\\\-///\-/-/\/
 */

/*
A Forth with extended indirect thread code

# RISCV considerations 

Using R32I, 32 bits cell, 

must be saved by subroutines (calee)

s4 ~X22~ as Rsp, return stack pointer
s5 ~X21~ as Psp, parameter stack pointer
s6 ~X20~ as Ipt, return register for jump and link
s7 ~X23~ as Top, Top on stack
s8 ~X24~ as Nos, Next on stack
s9 ~X25~ as Wrk, temporary scratch register

https://github.com/riscv-non-isa/riscv-asm-manual/blame/master/riscv-asm.md

The following example shows how to load an absolute address:

    lui  a0, %hi(msg + 1)
    addi a0, a0, %lo(msg + 1)
```
*/

//----------------------------------------------------------------------

/* using a GCC compiler */

 #define  FALSE 0
 #define  TRUE -1
 #define  CELL  4

 #define  Psp s4    //   parameter stack
 #define  Rsp s5    //   return stack 
 #define  Ipt s6    //   reference pointer
 #define  Top s7    //   Top on parameter stack
 #define  Nos s8    //   Next on parameter stack
 #define  Wrk s9    //   hold for
 #define  T0 s10    //   temporary
 #define  T1 s11    //   temporary

//----------------------------------------------------------------------
// stack macros
//
.macro rspull reg
    lw \reg, 0(Rsp)
    addi Rsp, Rsp, -1*CELL
.endm

.macro rspush reg
    sw \reg, 0(Rsp)
    addi Rsp, Rsp, CELL
.endm

.macro pspull reg
    lw \reg, 0(Psp)
    addi Psp, Psp, -1*CELL
.endm

.macro pspush reg
    sw \reg, 0(Psp)
    addi Psp, Psp, CELL
.endm

.macro link address
    jal zero, \address
.endm

.macro jump address
    jalr zero, \address, 0
.endm

//----------------------------------------------------------------------

.text
.global _forth_
_forth_:

//----------------------------------------------------------------------
//
// header of word in dictionary
//   byte flags must be 0x80, 0x40, 0x20, 0x10
//   byte size  must be 1 to 15
//   [link][size+flags][name][pad?]
//
//----------------------------------------------------------------------
//  Dictionary
//
//   compound	[ link,size+flags,name,pad?, ref, ..., ref , _inner_ ]
//   primitives	[ link,size+flags,name,pad?, 0x0, code, (jal zero, link) ]
//
//----------------------------------------------------------------------
//
// set start reverse linked list
//
// adapted from amforth-6.9
99:
.word 0
//97: # riscv-wordlist
//98: # environment
//99: # forth-wordlist

.set _link_, 0x0

// riscV are byte oriented, but address must be even :)
.macro header name, label, flags=0x0
is_\label:
    .p2align 1, 0x00
    .word 99b
99:
    .byte \flags
    .byte (3f - 2f) 
2:
    .ascii "\name"
3:
    .p2align 1, 0x20	
\label:
.endm

/***********************************************************************

    forth inner interpreter

***********************************************************************/
//----------------------------------------------------------------------
//
header "ENDS", "inner"
_inner: 
    .word 0x0

_unnest:
    rspull Ipt

_next: 
    lw Wrk, 0 (Ipt)
    addi Ipt, Ipt, CELL
    beq Wrk, zero, _jump

_nest: 
    rspush Ipt
    add Ipt, zero, Wrk

_link:    
    jal zero, _next

_jump:   
    add Wrk, Ipt, zero
    addi Ipt, Ipt, CELL
    jalr zero, Wrk, 0

//----------------------------------------------------------------------

/***********************************************************************

  basic primitives

***********************************************************************/
//----------------------------------------------------------------------
// ( -- 0 )
header "0", "zeru", 
    .word 0x0
    pspush Top 
    add Top, zero, zero  // li Top, 0
    jal zero, _link

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
header "0=", "zequ"    
    .word 0x0
    beq Top, zero, _ftrue
_ffalse:
    addi Top, zero, FALSE  // li Top, FALSE
    jal zero, _link
_ftrue:
    addi Top, zero, TRUE   // li Top, TRUE
    jal zero, _link

//----------------------------------------------------------------------
// ( w a -- )
header "!", "to", 
    .word 0x0
    pspull Nos
    sw Top, 0 (Nos)
    jal zero, _link

//----------------------------------------------------------------------
// ( a -- w )
header "@", "at", 
    .word 0x0
    lw Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
// ( -- rsp )
header "RS@", "rsat",
    .word 0x0
    pspush Top 
    add Top, zero, Rsp
    jal zero, _link

//----------------------------------------------------------------------
// ( -- psp )
header "PS@", "psat",
    .word 0x0
    pspush Top 
    add Top, zero, Psp
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "NAND", "nand",
    .word 0x0
    pspull Nos
    and Nos, Top, Nos
    neg Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "PLUS", "plus",
    .word 0x0
    pspull Nos
    add Top, Top, Nos
    jal zero, _link

/***********************************************************************

  more primitives

***********************************************************************/

//----------------------------------------------------------------------
// ( u -- w )
header "INVERT", "invert"
    .word 0x0
    xori Top, Top, -1
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- w )
header "NEGATE", "negate"
    .word 0x0
    sub Top, zero, Top 
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "MINUS", "minus",
    .word 0x0
    pspull Nos
    sub Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "SHR", "shr"
    .word 0x0
    pspull Nos
    srl Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "SHL", "shl"
    .word 0x0
    pspull Nos
    sll Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "AND", "and"
    .word 0x0
    pspull Nos
    and Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "OR", "or"
    .word 0x0
    pspull Nos
    or Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "XOR", "xor"
    .word 0x0
    pspull Nos
    xor Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- FALSE)
header "FALSE", "false", 
    .word 0x0
    pspush Top 
_isfalse:
    addi Top, zero, FALSE  // li Top, FALSE
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- TRUE)
header "TRUE", "true", 
    .word 0x0
    pspush Top 
_istrue:
    addi Top, zero, TRUE   // li Top, TRUE
    jal zero, _link

//----------------------------------------------------------------------
header "<", "lt", 
    .word 0x0
    pspull Nos
    blt Top, Nos, _istrue
    bge Top, Nos, _isfalse
    
//----------------------------------------------------------------------
header ">", "gt", 
    .word 0x0
    pspull Nos
    blt Nos, Top, _istrue
    bge Nos, Top, _isfalse
    
//----------------------------------------------------------------------
header "=", "eq", 
    .word 0x0
    pspull Nos
    beq Top, Nos, _istrue
    bne Top, Nos, _isfalse

//----------------------------------------------------------------------
header "<>", "neq", 
    .word 0x0
    pspull Nos
    bne Top, Nos, _istrue
    beq Top, Nos, _isfalse

//----------------------------------------------------------------------
header "1", "one", 
    .word 0x0
    pspush Top 
    addi Top, zero, 1  // li Top, 1
    jal zero, _link

//----------------------------------------------------------------------
header "2", "two", 
    .word 0x0
    pspush Top 
    addi Top, zero, 2  // li Top, 2
    jal zero, _link

//----------------------------------------------------------------------
header "CELL", "cell", 
    .word 0x0
    pspush Top 
    addi Top, zero, CELL   // li Top, CELL
    jal zero, _link

//----------------------------------------------------------------------
// CELL is 4, multiply by shift left
header "CELLS", "cells", 
    .word 0x0
    slli Top, Top, 2
    jal zero, _link

//----------------------------------------------------------------------
// CELL is 4, add a CELL size
header "CELL+", "cellp", 
    .word 0x0
    addi Top, Top, CELL
    jal zero, _link

//----------------------------------------------------------------------
// CELL is 4, sub a CELL size
header "CELL-", "cellm", 
    .word 0x0
    addi Top, Top, -1*CELL
    jal zero, _link

//----------------------------------------------------------------------
header ">R", "tor", 
    .word 0x0
    rspush Top 
    pspull Top 
    jal zero, _link

//----------------------------------------------------------------------
header "R>", "rto", 
    .word 0x0
    pspush Top 
    rspull Top 
    jal zero, _link

//----------------------------------------------------------------------
header "@R", "atr", 
    .word 0x0
    pspush Top 
    lw Top, 0 (Rsp)
    jal zero, _link

//----------------------------------------------------------------------
//   ( rs -- )
header "R!", "rsto", 
    .word 0x0
    add Rsp, zero, Top 
    jal zero, _pull
    
//----------------------------------------------------------------------
//   ( ps -- )
header "P!", "psto", 
    .word 0x0
    add Psp, zero, Top 
    jal zero, _pull

//----------------------------------------------------------------------
//   ( w -- )
header "DROP", "drop", 
    .word 0x0
_pull:
    pspull Top 
    jal zero, _link

//----------------------------------------------------------------------
//   ( w -- w w )
header "DUP", "dup", 
    .word 0x0
_push:
    pspush Top 
    jal zero, _link

//----------------------------------------------------------------------
//   ( w v -- v w )
header "SWAP", "swap", 
    .word 0x0
    pspull Nos
_swap:    
    pspush Top 
    mv Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   (w v -- w v w)
header "OVER", "over", 
    .word 0x0
    lw Nos, CELL (Psp)
    jal zero, _swap
    
//----------------------------------------------------------------------
//   (w u v -- u v w)
header "ROT", "rot", 
    .word 0x0
    pspull Wrk
    pspull Nos
    pspush Wrk
    jal zero, _swap
    
//----------------------------------------------------------------------
//   ( 0 -- 0 ) (w -- w w)
header "?DUP", "zdup", 
    .word 0x0
    beq Top, zero, 1f
    pspush Top 
1:    
    jal zero, _link

//----------------------------------------------------------------------
// trick, load Top <- (IP)
// used by constant, leaves a value onto Top, also know as doLit
header "DOCON", "DOCON", 
    .word 0x0
    pspush Top 
    lw Top, 0(Ipt)
    jal zero, _skip

//----------------------------------------------------------------------
// trick, load Top <- IP
// used by variable, leaves a reference onto Top,  
header "DOVAR", "DOVAR", 
    .word 0x0
    pspush Top 
    add Top, zero, Ipt
    jal zero, _skip

//----------------------------------------------------------------------
// trick, if Top not zero skip next reference, drop Top
header "?BRANCH", "zbranch", 
    .word 0x0
    add Wrk, zero, Top 
    pspull Top 
    beq Wrk, zero, _branch
_skip:
    addi Ipt, Ipt, CELL
    jal zero, _link
    
//----------------------------------------------------------------------
// trick, a follow reference is always a offset to branch
header "BRANCH", "branch", 
    .word 0x0
_branch:    
    lw Wrk, 0 (Ipt)
    add Ipt, Ipt, Wrk
    jal zero, _link

//----------------------------------------------------------------------
// trick, a Top reference is pushed into return stack
header "EXECUTE", "execute", 
    .word 0x0
    rspush Top 
    pspull Top
    jal zero, _pull
    
//  ZZZZ >< ABS ALLIGN 

//----------------------------------------------------------------------
//   ( b a -- ) 
// writes one byte at address, unsigned
header "C!", "cto", 
    .word 0x0
    pspull Nos
    sb Nos, 0 (Top)
    jal zero, _pull

//----------------------------------------------------------------------
//   ( a -- b )
// reads one byte from address, unsigned
header "C@", "cat", 
    .word 0x0
    lbu Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
//   ( w a --  )
// reads one byte from address
header "+!", "plusto", 
    .word 0x0
    pspull Nos
    lw Wrk, 0 (Top)
    add Wrk, Wrk, Nos
    sw Wrk, 0 (Top)
    jal zero, _pull

//----------------------------------------------------------------------
//   ( a1 a2 u --- FALSE | TRUE )
// compare bytes from source++ to destination++, decrease count--
// returns 0 if equal (no differ)
// used most to compare names with less than 16 of length
// 
HEADER "CSAME", "csame"
    .word 0x0
    pspull Nos
    pspull Wrk

    add T0, zero, zero
1:
    beq Top, zero, 2f
    lb T0, 0 (Wrk)
    lb T1, 0 (Nos)
    xor T0, T1, T0
    bne T0, zero, 2f

    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    addi Top, Top, -1
    jal zero, 1b
2:
    // results
    add Top, zero, T0
    jal zero, _link
    
//----------------------------------------------------------------------
//   ( a1 a2 u --- )
// move bytes from source++ to destination++, decrease count--
// returns 0 if equal (no differ)
//
HEADER "CMOVE", "cmove"
    .word 0x0
    pspull Nos
    pspull Wrk
1:
    beq Top, zero, 2f
    lb T0, 0(Wrk)
    sb T0, 0(Nos)
    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    addi Top, Top, -1
    jal zero, 1b
2:
    jal zero, drop

//----------------------------------------------------------------------
//   ( a1 a2 u --- )
// move bytes from source-- to destination--, decrease count--
// offsets calculated inside
// returns 0 if equal (no differ)
//
HEADER "BMOVE", "bmove"
    .word 0x0
    pspull Nos
    pspull Wrk

// do offsets    
    add Nos, Nos, Top 
    add Wrk, Wrk, Top 
1:
    beq Top, zero, 2f
    lb T0, 0(Wrk)
    sb T0, 0(Nos)
    addi Wrk, Wrk, -1
    addi Nos, Nos, -1
    addi Top, Top, -1
    jal zero, 1b
2:
    jal zero, drop
    
//----------------------------------------------------------------------
HEADER "_EOF_", "_eof_"

#include "table.S"


