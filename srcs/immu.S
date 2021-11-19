
/*
 *  DISCLAIMER
 *
 *  Copyright © 2021, Alvaro Gomes Sobral Barcellos,
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
 *
 *  licensed with GPL 2.0
 *
 */

/*
A Forth with extended indirect thread code

(S: w1 w2 w3 -- w1 w3) parameter stack, before -- after, w3 at top
(R: w1 w2 w3 -- w1 w3) return stack, before -- after, w3 at top

simetric division, floored to zero

// RISCV considerations 

Using R32IM, 32 bits cell, 

must be saved by subroutines (calee)

( a PDP-11 )
s4 ~X20~ as Rsp, return stack pointer
s5 ~X21~ as Psp, parameter stack pointer
s6 ~X22~ as Ipt, return register for jump and link
s7 ~X23~ as Top, Top on stack
s8 ~X24~ as Nos, Next on stack, pull when need
s9 ~X25~ as Wrk, temporary scratch register

( extras )
s10 ~X26~ as T0, temporary extra
s11 ~X27~ as T1, temporary extra

Why T0 and T1 ? 

To make a memcmp needs five registers 
two for address sources, two for contents bytes, 
and maybe a counter.
else many stack operations are need

```
*/

//----------------------------------------------------------------------

/* using a GCC compiler */

#define  FALSE 0
#define  TRUE -1
#define  BYTE  1
#define  CELL  4
#define  STACK 18
#define  BUFFER 80
#define  LENGTH 16

#define  FLASHPAGE 1024    # page of flash memory for flush in GD32VF103CBT6

#define F_IMMEDIATE 0x80
#define F_COMPILE_ONLY 0x40
#define F_HIDDEN  0x20
#define F_TOGGLED  0x10
#define F_COMMON  0x00

#define F_TOMASK  0xF0
#define F_UNMASK  0x0F

#define IS_COMPILE  0x01
#define IS_EXECUTE  0x00

//---------------------------------------------------------------------
// Flow Control
// assumes that all line edit is done at remote!
// no delete, no moving cursor, just a static line.
// works as a screen or block, just receives a line till a CR or CR LF
// uses BS, ESC, CAN, XON, XOFF, for control
//

#define EOF_      0x05    //#; ascii eof ^D

#define XON_      0x11    //#; ascii DC1 ^Q
#define XOFF_     0x13    //#; ascii DC3 ^S

#define CR_       0x0d    //#; ascci carriage return ^M
#define LF_       0x0a    //#; ascii line feed ^J

#define CAN_      0x18    //#; ascii cancel ^C
#define ESC_      0x1B    //#; ascii escape ^[

#define BS_       0x08    //#; ascii backspace ^H
#define TB_       0x09    //#; ascii horizontal ^I

#define BL_       0x20    //#; ascii space
#define TL_       0x7E    //#; ascii tilde

#define NUL_      0x00    //#; ascii NUL ^@
 
//---------------------------------------------------------------------
 
#define  Psp s4    //#   parameter stack
#define  Rsp s5    //#   return stack 
#define  Ipt s6    //#   reference pointer
#define  Top s7    //#   Top on parameter stack
#define  Nos s8    //#   Next on parameter stack
#define  Wrk s9    //#   hold for
#define  T0 s10    //#   temporary
#define  T1 s11    //#   temporary

//----------------------------------------------------------------------
// stack macros
// could have hooks for check over/under
//
.macro spull stack, register
    lw \register, 0 (\stack)
    addi \stack, \stack, -1*CELL
.endm

.macro spush stack, register
    sw \register, 0 (\stack)
    addi \stack, \stack, CELL
.endm

.macro scopy stack, register, index
    lw \register, \index * CELL (\stack)
.endm

.macro link address
    jal zero, \address
.endm

.macro jump address
    jalr zero, \address, 0
.endm

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
//   compound	[ link,size+flags,name,pad?, ref, ..., ref , EXIT ]
//   primitives	[ link,size+flags,name,pad?, 0x0, code, (jal zero, link) ]
//
//----------------------------------------------------------------------

// riscV are byte oriented, but address must be even, and word bounds for branch :)
// compiler only puts address at elf
// exclusive bytes for size and flags, easy way
// numeric labels only 0-99, 
// 99b does linked list to previous word
//
//;
//; set start reverse linked list
//;
 
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
    .p2align 2, 0x20	
\label:
.endm


/***********************************************************************

    forth inner constants and variables

***********************************************************************/

.data

// .fill <bytes> reserves and initializes
// .skip <bytes> reserves but dont initialize

VOID:
.word 0x0

// return stack
XRSP:
.fill STACK, CELL, 0x0

//parameter stack
XPSP:
.fill STACK, CELL, 0x0

// terminal input buffer
XTIB:
.fill BUFFER, BYTE, 0x0

// flash buffer for flush
XFIF:
.fill FLASHPAGE, BYTE, 0x0

// next free flash address, for words
FREEF:
.word 0x0

// next free sram address, for variables
FRAMF:
.word 0x0

// source input address
TIBF:
.word 0x0

// cursor in TIB
TOIN:
.word 0x0

// numeric radix
BASE:
.word 0x0

// state of interpreter, 0 = interpret, 1 = compile
STATE:
.word 0x0

// link to latest word in dictionary
LATEST:
.word 0x0

// system flags
FLAGS:
.word 0x0

// seed for random
SEED:
.word 0x0

// turn on routine after boot
TURN:
.word 0x0

// turn of routine before boot
REST:
.word 0x0

// page of flash in sram 
PAGE:
.word 0x0

// context, where to search a word, reference of vocabulary
CONTXT:
.word 0x0

// current, where to create a word, reference of vocabulary
CURTXT:
.word 0x0

/***********************************************************************

    forth inner interpreter

    note: The conditional branch range is ±4 KiB.
          near jump could be beq zero, zero, _this

norvc
norelax

***********************************************************************/
.text

.global _start
_start:

.global _forth_
_forth_:

// set start reverse linked list
// trick adapted from amforth-6.9
99:
.word 0

//----------------------------------------------------------------------
//
header "ENDS", "ends"
_inner: 
    .word 0x0

_unnest:
    spull Rsp, Ipt

_next: 
    lw Wrk, 0 (Ipt)
    addi Ipt, Ipt, CELL
    beq Wrk, zero, _jump

_nest: 
    spush Rsp, Ipt
    add Ipt, Wrk, zero

_link:    
    jal zero, _next

_jump:   
    add Wrk, Ipt, zero
    addi Ipt, Ipt, CELL
    jalr zero, Wrk, 0

//----------------------------------------------------------------------

/*
// vide https://github.com/ScannedInAvian/riscyforth/blob/main/boot.S
*/
//----------------------------------------------------------------------
//   ( -- )
header "KEY", "key", 
    .word 0x0
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- )
header "EMIT", "emit", 
    .word 0x0
    jal zero, _link

/***********************************************************************

  basic primitives
  all primitives must have a 0x0 at start
  order is critical because beq/bne/blt/bgt does only +/- 2 Mib offsets

***********************************************************************/
//----------------------------------------------------------------------
//   ( -- )
header "NOOP", "noop", 
    .word 0x0
_noop: 
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- FALSE)
header "FALSE", "false", 
    .word 0x0
    spush Psp, Top 
_isfalse:
    addi Top, zero, FALSE  
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- TRUE)
header "TRUE", "true", 
    .word 0x0
    spush Psp, Top 
_istrue:
    addi Top, zero, TRUE   
    jal zero, _link

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
header "0=", "zequ"    
    .word 0x0
    beq Top, zero, _istrue
    bne Top, zero, _isfalse

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE) xxxx
header "0>", "zgth"    
    .word 0x0
    blt zero, Top, _istrue
    bge zero, Top, _isfalse 

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
header "0<", "zlth"    
    .word 0x0
    blt Top, zero, _istrue
    bge Top, zero, _isfalse 

//----------------------------------------------------------------------
header "=", "equ", 
    .word 0x0
    spull Psp, Nos
    beq Top, Nos, _istrue
    bne Top, Nos, _isfalse

//----------------------------------------------------------------------
// (n1 n2 -- n1 > n2)
header ">", "greaterth", 
    .word 0x0
    spull Psp, Nos
    blt Top, Nos, _istrue
    bge Top, Nos, _isfalse
    
//----------------------------------------------------------------------
// (n1 n2 -- n1 < n2)
header "<", "lessth", 
    .word 0x0
    spull Psp, Nos
    blt Nos, Top, _istrue
    bge Nos, Top, _isfalse
    
//----------------------------------------------------------------------
// ( w a -- )
header "!", "to", 
    .word 0x0
    spull Psp, Nos
    sw Top, 0 (Nos)
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( a -- w )
header "@", "at", 
    .word 0x0
    lw Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u+v )
header "+", "plus",
    .word 0x0
    spull Psp, Nos
    add Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u-v )
header "-", "minus",
    .word 0x0
    spull Psp, Nos
    sub Top, Nos, Top
    jal zero, _link

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
// ( u v -- u>>v )
header "2*", "twostar"
    .word 0x0
    spull Psp, Nos
    srli Top, Top, 1
    jal zero, _link

/----------------------------------------------------------------------
// ( u v -- u>>v )
header "2/", "twoslash"
    .word 0x0
    spull Psp, Nos
    slli Top, Top, 1
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u<<v  )
header "LSHIFT", "lshift"
    .word 0x0
    spull Psp, Nos
    sll Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u>>v )
header "RSHIFT", "rshift"
    .word 0x0
    spull Psp, Nos
    srl Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "AND", "andf"
    .word 0x0
    spull Psp, Nos
    and Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "OR", "orf"
    .word 0x0
    spull Psp, Nos
    or Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "XOR", "xorf"
    .word 0x0
    spull Psp, Nos
    xor Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "NAND", "nandf",
    .word 0x0
    spull Psp, Nos
    and Nos, Top, Nos
    neg Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0x20 )
header "BL", "bl", 
    .word 0x0
    spush Psp, Top 
    addi Top, zero, BL_
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0x0 )
header "0", "nil", 
    .word 0x0
    spush Psp, Top 
    add Top, zero, zero
    jal zero, _link

//----------------------------------------------------------------------
// ( -- -1 )
header "-1", "oneneg", 
    .word 0x0
    spush Psp, Top 
    add Top, zero, -1
    jal zero, _link

//----------------------------------------------------------------------
// ( -- -2 )
header "-2", "twoneg", 
    .word 0x0
    spush Psp, Top 
    add Top, zero, -2
    jal zero, _link

//----------------------------------------------------------------------
// ( -- +1 )
header "1", "one", 
    .word 0x0
    spush Psp, Top 
    addi Top, zero, 1
    jal zero, _link

//----------------------------------------------------------------------
// ( -- +2 )
header "2", "two", 
    .word 0x0
    spush Psp, Top 
    addi Top, zero, 2
    jal zero, _link

//----------------------------------------------------------------------
// ( -- CELL )
header "CELL", "cell", 
    .word 0x0
    spush Psp, Top 
    addi Top, zero, CELL
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- u*CELL )
// CELL is 4, multiply by shift left
header "CELLS", "cells", 
    .word 0x0
    slli Top, Top, 2
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- u+CELL )
// CELL is 4, add a CELL size
header "CELL+", "cellplus", 
    .word 0x0
    addi Top, Top, CELL
    jal zero, _link

//----------------------------------------------------------------------
// CHAR is one byte, just add zero 
// ( u -- u*BYTE )
// hook 
header "CHARS", "chars", 
    .word 0x0
    add Top, Top, zero
    jal zero, _link

//----------------------------------------------------------------------
// CHAR is one byte, add a char size
// ( u -- u+BYTE )
header "CHAR+", "charplus", 
    .word 0x0
    addi Top, Top, BYTE
    jal zero, _link

//----------------------------------------------------------------------
header ">R", "tor", 
    .word 0x0
    spush Rsp, Top 
    spull Psp, Top 
    jal zero, _link

//----------------------------------------------------------------------
header "R>", "rto", 
    .word 0x0
    spush Psp, Top 
    spull Rsp, Top 
    jal zero, _link

//----------------------------------------------------------------------
header "R@", "rat", 
    .word 0x0
    spush Psp, Top 
    lw Top, 0 (Rsp)
    jal zero, _link

//----------------------------------------------------------------------
//   ( rs -- )
header "RS!", "rsto", 
    .word 0x0
    add Rsp, Top, zero 
    jal zero, _drop
    
//----------------------------------------------------------------------
//   ( ps -- )
header "PS!", "psto", 
    .word 0x0
    add Psp, Top, zero
    jal zero, _drop

//----------------------------------------------------------------------
//   ( rs -- )
header "RS@", "rsat", 
    .word 0x0
	spush Psp, Top
    add Top, Rsp, zero 
    jal zero, _drop
    
//----------------------------------------------------------------------
//   ( ps -- )
header "PS@", "psat", 
    .word 0x0
	spush Psp, Top
    add Top, Psp, zero
    jal zero, _drop

//----------------------------------------------------------------------
//   ( u w -- u )
header "DROP", "drop", 
    .word 0x0
_drop:
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- w )
header "NIP", "nip", 
    .word 0x0
    spull Psp, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   ( 0 -- 0 ) (w -- w w)
header "?DUP", "zdup", 
    .word 0x0
    bne Top, zero, _dup  
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- u w w )
header "DUP", "dup", 
    .word 0x0
_dup:
    spush Psp, Top 
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- u u w )
header "DIP", "dip", 
    .word 0x0
    lw Nos, 0 (Psp)
_dip:
    spush Psp, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- w u w )
header "TUCK", "tuck", 
    .word 0x0
    spull Psp, Nos
    spush Psp, Top
    beq zero, zero, _dip

//----------------------------------------------------------------------
//   ( u w -- u w u )
header "OVER", "over", 
    .word 0x0
    lw Nos, 0 (Psp)
    spush Psp, Top
_n2t:
    add Top, Nos, zero
    jal zero, _link
    
//----------------------------------------------------------------------
//   ( v u w -- v w u )
header "SWAP", "swap", 
    .word 0x0
    lw Nos, 0 (Psp)
    sw Top, 0 (Psp)
    beq zero, zero, _n2t

//----------------------------------------------------------------------
//   (v u w -- u w v)
header "ROT", "rot", 
    .word 0x0
    lw Wrk, 0 (Psp)
    lw Nos, CELL (Psp)
    sw Wrk, CELL (Psp)
    sw Top, 0 (Psp)
    beq zero, zero, _n2t
    
//----------------------------------------------------------------------
//   (v u w -- w v u)
header "-ROT", "nrot", 
    .word 0x0
    lw Nos, 0 (Psp)
    lw Wrk, CELL (Psp)
    sw Top, CELL (Psp)
    sw Wrk, 0 (Psp)
    beq zero, zero, _n2t
    
//----------------------------------------------------------------------
//   (v u w -- w u v)
header "FLIP", "flip", 
    .word 0x0
    lw Nos, CELL (Psp)
    sw Top, CELL (Psp)
    beq zero, zero, _n2t
    
//----------------------------------------------------------------------
//   ( v u w -- u v w )
header "SWIP", "swip", 
    .word 0x0
    lw Nos, 0 (Psp)
    lw Wrk, CELL (Psp)
    sw Nos, CELL (Psp)
    sw Wrk, 0 (Psp)
    jal zero, _link

//----------------------------------------------------------------------
header "MIN", "min", 
    .word 0x0
    spull Psp, Nos
    blt Top, Nos, _noop 
    beq zero, zero, _n2t
  
//----------------------------------------------------------------------
header "MAX", "max", 
    .word 0x0
    spull Psp, Nos
    blt Nos, Top, _noop 
    beq zero, zero, _n2t
  
//----------------------------------------------------------------------
// trick, load Top <- (IP)
// used by constant, leaves the contents of next cell from dictionary onto Top, aka doLit
header "DOCON", "docon", 
    .word 0x0
dolit:
    spush Psp, Top 
    lw Top, 0 (Ipt)
_nobranch:
    addi Ipt, Ipt, CELL
    jal zero, _link

//----------------------------------------------------------------------
// trick, load Top <- IP
// used by variable, leaves a reference onto Top,  
header "DOVAR", "dovar", 
    .word 0x0
    spush Psp, Top 
    add Top, Ipt, zero
    beq zero, zero, _nobranch
  
//----------------------------------------------------------------------
// trick, branch if Top is zero else skip next reference
header "?BRANCH", "zbranch", 
    .word 0x0
    beq Top, zero, _branch
    beq zero, zero, _nobranch
    
//----------------------------------------------------------------------
// trick, a follow reference is always a offset to branch
header "BRANCH", "branch", 
    .word 0x0
_branch:    
    lw Wrk, 0 (Ipt)
    add Ipt, Ipt, Wrk
    jal zero, _link

//----------------------------------------------------------------------
//   ( b a -- ) 
// writes one byte at address, unsigned
header "C!", "cto", 
    .word 0x0
    spull Psp, Nos
    sb Nos, 0 (Top)
    beq zero, zero, _drop
  
//----------------------------------------------------------------------
//   ( a -- b )
// reads one byte from address, unsigned
header "C@", "cat", 
    .word 0x0
    lbu Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
//   ( w a --  )
// add to contents of a address
header "+!", "plusto", 
    .word 0x0
    spull Psp, Nos
    lw Wrk, 0 (Top)
    add Wrk, Wrk, Nos
    sw Wrk, 0 (Top)
    beq zero, zero, _drop
  
//----------------------------------------------------------------------
// from amforth 6.9
//   ( a -- b )
// aligns a address to next CELL
header "ALIGNED", "aligned", 
    .word 0x0
    andi Wrk, Top, 1
    add Top, Top, Wrk
    andi Wrk, Top, 2 
    add Top, Top, Wrk
    jal zero, _link

// -----------------------------------------------------------------------------
// ok multiply ( w1 w2 w3 -- ((w1 * w2) / w3) ) zzzz
header "*/", "starslash", 
    .word 0x0
    spull Psp, Nos
    mul Top, Top, Nos
    spull Psp, Nos
    div Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok multiply ( w1 w2 -- w1 * w2 )
header "*", "star", 
    .word 0x0
    spull Psp, Nos
    mul Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
 // ok unsigned multiply ( w1 w2 -- w1 * w2 )
header "m*", "mstar", 
    .word 0x0
    lw Nos, 0 (Psp)
    mul Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    mulh Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok unsigned multiply ( w1 w2 -- w1 * w2 )
header "um*", "umstar", 
    .word 0x0
    lw Nos, 0 (Psp)
    mul Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    mulhu Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok divide ( w1 w2 -- quotient )
header "/", "slash", 
    .word 0x0
    spull Psp, Nos
    div Top, Nos, Top
    jal zero, _link

// -----------------------------------------------------------------------------
// ok module ( w1 w2 -- remainder ) 
header "mod", "module", 
    .word 0x0
    spull Psp, Nos
    rem Top,  Nos, Top
    jal zero, _link

// -----------------------------------------------------------------------------
// ok dual divide ( w1 w2 -- remainder quotient )
header "/mod", "slashmod", 
    .word 0x0
    lw Nos, 0 (Psp)
    rem Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    div Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok unsigned dual divide  ( w1 w2 -- remainder quotient )
header "u/mod", "uslashmod", 
    .word 0x0
    lw Nos, 0 (Psp)
    remu Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    divu Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// does for limit to 0
// do for S:(limit -- ) R:(limit 0 -- )
header "(FOR)", "xfor", F_COMPILER_ONLY
    .word 0x0
    spush Rsp, Top
    spull Psp, Top
    spush Rsp, zero
    jal zero, _link

//----------------------------------------------------------------------
// generic case, any value to index
// do do S:(index limit -- ) R:(limit index -- )
header "(DO)", "xdo", F_COMPILER_ONLY
    .word 0x0
    spush Rsp, Top
    spull Psp, Top
    spush Rsp, Top
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
// really do a loop
// do next R:(limit index --)
    header "(NEXT)", "xnext", F_COMPILER_ONLY
    .word 0x0
    lw Nos, 0 (Rsp)
    addi Nos, Nos, -1
    beq zero, zero, _loopsdown


//----------------------------------------------------------------------
// increase index by one, loops while index less than limit
// do loop R:(limit index --)
    header "(LOOP)", "xloop", F_COMPILER_ONLY
    .word 0x0
    lw Nos, 0 (Rsp)
    addi Nos, Nos, 1
    beq zero, zero, _loopsup
    
//----------------------------------------------------------------------
// increase index by Top, loops while index less than limit
// dolooplus R:(limit index --)
    header "(+LOOP)", "xlooplus", F_COMPILER_ONLY
    .word 0x0
    lw Nos, 0 (Rsp)
    addi Nos, Nos, Top
    spull Psp, Top
    beq zero, zero, _loopsup

//----------------------------------------------------------------------
// copy limit to  index 
// leave R:(limit index --)
    header "(UNLOOP)", "xunloop", F_COMPILER_ONLY
    .word 0x0
_unloop:
    addi Rsp, Rsp, -2*CELL
    beq zero, zero, _nobranch
_loopsup:
    lw Wrk, CELL (Rsp)
    bge Nos, Wrk, _unloop
    sw Nos, 0 (Rsp)
    beq zero, zero, _branch
_loopsdown:
    lw Wrk, CELL (Rsp)
    bge Wrk, Nos, _unloop
    sw Nos, 0 (Rsp)
    beq zero, zero, _branch

//----------------------------------------------------------------------
//   ( a1 a2 u --- )
// move cells (32bit) from a1 source++ to a2 destination++, decrease count--
// returns 0 if equal (no differ)
//
header "MOVE", "move"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk
1:
    beq Top, zero, 2f
    lw T0, 0(Wrk)
    sw T0, 0(Nos)
    addi Wrk, Wrk, CELL
    addi Nos, Nos, CELL
    addi Top, Top, -1
    beq zero, zero, 1b
2:
    jal zero, _drop

//----------------------------------------------------------------------
//   ( a1 a2 u --- )
// move bytes from a1 source++ to a2 destination++, decrease count--
// returns 0 if equal (no differ)
//
header "CMOVE", "cmove"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk
1:
    beq Top, zero, 2f
    lb T0, 0(Wrk)
    sb T0, 0(Nos)
    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    addi Top, Top, -1
    beq zero, zero, 1b
2:
    jal zero, _drop

//----------------------------------------------------------------------
//   ( a1 a2 u --- )
// move bytes from source-- to destination--, decrease count--
// offsets calculated inside
// returns 0 if equal (no differ)
//
header "CMOVE>", "cmoveb"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk
 
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
    beq zero, zero, 1b
2:
    jal zero, _drop

//----------------------------------------------------------------------
//   ( a1 a2 u --- FALSE | TRUE )
// compare bytes, from a1 source++ to a2 destination++, decrease u count--
// returns 0 if equal (no differ)
// 
header "CSAME", "csame"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk
1:
    beq Top, zero, 4f
    lb T0, 0 (Wrk)
    lb T1, 0 (Nos)
    bne T0, T1, 2f
    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    addi Top, Top, -1
    beq zero, zero, 1b
2:
    add Top, T0, zero
4:
    jal zero, _link

 //----------------------------------------------------------------------
//   ( a u c --- )
// copy  (c) byte to (a) destination++, decrease (u) count--
//
header "CFILL", "cfill"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk
1:
    beq Nos, zero, 2f
    sb Top, 0(Wrk)
    addi Wrk, Wrk, 1
    addi Nos, Nos, -1
    beq zero, zero, 1b
2:
    spull Psp, Top 
    jal zero, drop
   
//----------------------------------------------------------------------
//   ( c a1  --- a2 )
// point next non c
// returns 0 at end of buffer
//
header "cskip", "cskip"
    .word 0x0
    // get the separator char
    spull Psp, Nos

1:  // while (top) == c
    lb Wrk, 0 (Top)
    beq Wrk, zero, 3f
    bne Wrk, Nos, 2f
    addi Top, Top, 1
    beq zero, zero, 1b
2:  
    jal zero, _link
3:   
    add Top, Wrk, zero
    jal zero, _link

//----------------------------------------------------------------------
//   ( c a1  --- a2 )
// point next c
// returns 0 at end of buffer
//
header "cfind", "cfind"
    .word 0x0
    // get the separator char
    spull Psp, Nos

1:  // while (top) != c
    lb Wrk, 0 (Top)
    beq Wrk, zero, 3f
    beq Wrk, Nos, 2f
    addi Top, Top, 1
    beq zero, zero, 1b
2:  
    jal zero, _link
3:   
    add Top, zero, zero
    jal zero, _link

//----------------------------------------------------------------------
// ( <ch> a1  --- 0 | a2 u )
// point next word between <ch><ch><ch>sssssss<ch>
// returns 0 at end of buffer
//
header "sscan", "sscan"
    .word 0x0
    // get the separator char
    spull Psp, Nos

1:  // while (top) == c
    lb Wrk, 0 (Top)
    beq Wrk, zero, 6f
    bne Wrk, Nos, 2f
    addi Top, Top, 1
    beq zero, zero, 1b

2:  // push start address
    spush Psp, Top

3:  // wile (top) != c
    lb Wrk, 0 (Top)
    beq Wrk, zero, 5f
    beq Wrk, Nos, 4f
    addi Top, Top, 1
    beq zero, zero, 3b

4:  // return lenght in Top
    lw Wrk, 0 (Psp)
    sub Top, Top, Wrk
    jal zero, _link

5:  // pull saved address
    spull Psp, Wrk

6:  // NIL (0x0) is end of buffer 
    add Top, zero, zero
    jal zero, _link

//---------------------------------------------------------------------- 
//   ( a1 a2 --- a1 0 | a1 a3 )
// search vocabulary at a2 for counted string at a1
// return a3 (lfa) or zero
// bytes: link(4),flags(1),size(1),name(n),pads(?)
//
header "sfind", "sfind"
    .word 0x0
1:
    // copy cstr address
    scopy Psp, Nos, 0
2:  
    lw Wrk, 0 (Top)     // point to lfa
    beq Wrk, zero, 8f   // end of vocabulary

    lw Top, 0 (Wrk)           // update to link
    // check size and first char
    lh T0, (CELL+1) (Wrk)   
    lh T1, 0 (Nos)
    // if doesn't match, try next one
    bne T0, T1, 2b

// size and first char match
    // push lfa
    spush Psp, Wrk

    // load length
    lb Top,  (CELL+1) (Wrk)
3:    
    // compare all name
    addi Top, Top, -1
    beq Top, zero, 5f
    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    lb T0, (CELL+1) (Wrk)
    lb T1, 0 (Nos)
    beq T0, T1, 3b
4:
    // not same, try next word
    spull Psp, Top
    beq zero, zero, 1b
5:  
    // found it
    spull Psp, Wrk
8:
    // leaves string at stack
    // and a zero as not found
    add Top, Wrk, zero
9: 
    jal zero, _link 
//----------------------------------------------------------------------

/***********************************************************************
    
    depends on dictionary linked list header structure

***********************************************************************/

//---------------------------------------------------------------------- 
// ok  ( lfa -- flag )
header  ">FLAGS", "toflags", 
    .word 0x0
    lb Top, (CELL) (Top)
    jal zero, _link
    
//---------------------------------------------------------------------- 
// ok  ( lfa -- nfa )
header  ">NAME", "toname", 
    .word 0x0
    lb Top, (CELL+1) (Top)
    jal zero, _link
    
//---------------------------------------------------------------------- 
// ok  ( lfa -- cfa )
header  ">BODY", "tobody", 
    .word 0x0
    // for sake all code must be CELL aligned, must use .p2align 2 
    // get length
    lb Wrk, (CELL+1) (Top)
    // add offset
    addi Top, Wrk, (CELL+2)
	// align it
    andi Wrk, Top, 1
    add Top, Top, Wrk
    andi Wrk, Top, 2 
    add Top, Top, Wrk
    jal zero, _link

//----------------------------------------------------------------------
header "_EOW_", "_eoW_"
    .word 0x0

#include "biosv.S"

#include "words.S"

header "_EOF_", "_eoF_"
    .word 0x0

/*
1       1st     fst,    first
2       2nd     snd,    second
3       3rd     thd,    third
4       4th     fth,    fourth
*/
