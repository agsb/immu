
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
A Forth with minimal indirect thread code

(S: w1 w2 w3 -- w1 w3) parameter stack, before -- after, w3 at top
(R: w1 w2 w3 -- w1 w3) return stack, before -- after, w3 at top

simetric division, floored to zero

// RISCV considerations 

Using R32IM, 32 bits cell, 

must be saved by subroutines (calee)

( a PDP-11 )
s4 ~X20~ as Rsp, return stack pointer
s5 ~X21~ as Psp, parameter stack pointer
s6 ~X25~ as Lnk, Link pointer, reserved  
s7 ~X24~ as Wrk, temporary scratch register
s8 ~X22~ as Top, Top on stack, reserved
s9 ~X23~ as Nos, Next on stack, when need

( extras )
s10 ~X26~ as T0, temporary extra
s11 ~X27~ as T1, temporary extra

Why T0 and T1 ? 

To make easy memmov, memcpy.
A mem needs five registers 
two for address sources, two for contents bytes, 
and maybe a counter.
else many stack operations are need

```
*/

//----------------------------------------------------------------------

/* using a GCC compiler */

#define  TRUE -1
#define  FALSE 0
#define  BYTE  1
#define  CELL  4
#define  STACK 18
#define  BUFFER 80
#define  LENGTH 16

#define  FLASHPAGE 1024    # page of flash memory for flush in GD32VF103CBT6

#define F_RESERVED 0x80
#define F_IMMEDIATE 0x40
#define F_COMPILE 0x20
#define F_HIDDEN  0x10
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
// uses ESC, CAN, XON, XOFF, for control
//
:
// #define EOF_      0x05    //#; ascii eof ^D
// #define TB_       0x09    //#; ascii horizontal ^I

#define XON_      0x11    //#; ascii DC1 ^Q
#define XOFF_     0x13    //#; ascii DC3 ^S

// #define CAN_      0x18    //#; ascii cancel ^C

#define ESC_      0x1B    //#; ascii escape ^[

// #define TL_       0x7E    //#; ascii tilde
// #define DEL_      0x7F    //#; ascii del

#define CR_       0x0d    //#; ascci carriage return ^M

#define LF_       0x0a    //#; ascii line feed ^J

#define BS_       0x08    //#; ascii backspace ^H

#define BL_       0x20    //#; ascii space

#define NL_       0x00    //#; ascii NUL ^@
 
//---------------------------------------------------------------------

// RISC-V callee saved registers

#define  Psp s4    //#   parameter stack
#define  Rsp s5    //#   return stack 
#define  Top s6    //#   hold, the top on parameter stack
#define  Nos s7    //#   work, scratch  
#define  Wrk s8    //#   work, scratch
#define  T0  s9    //#   temporary
#define  T1  s10   //#   temporary

//----------------------------------------------------------------------
// stack macros
// could have hooks for check over/under
//

// pull increases
.macro spull stack, register
    lw \register, 0 (\stack)
    addi \stack, \stack, CELL
.endm

// push decreases
.macro spush stack, register
    addi \stack, \stack, -1 * CELL
    sw \register, 0 (\stack)
.endm

.macro scopy stack, register, index
    lw \register, \index * CELL (\stack)
.endm

.macro move destin, origin
    add \destin, \origin, \zero
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
//   compound	[ link,size+flags,name,pad?, ref, ..., ref , ENDS ]
//   primitives	[ link,size+flags,name,pad?, 0x0, code, (jal zero, link) ]
//
//----------------------------------------------------------------------

// riscV are byte oriented, but address must be even, 
// and word bounds for branch :)
// compiler only puts address at elf
// exclusive bytes for size and flags, easy way
// numeric labels only 0-99, 
// 99b does linked list to previous word
//
//;
//; set start reverse linked list
//;
 
.macro header name, label, flags=0x0, leaf
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

; only for primitives
.if leaf
    .word 0x0
.endif

\label:
.endm

/***********************************************************************

    forth inner constants and variables

***********************************************************************/

.data

// .fill <bytes> reserves and initializes
// .skip <bytes> reserves but dont initialize

VOID:

// return stack:1

XRP:
.fill STACK, CELL, 0x0

//parameter stack
XSP:
.fill STACK, CELL, 0x0

// terminal input buffer
XTIB:
.fill BUFFER, BYTE, 0x0

// cursor in TIB
TOIN:

// numeric radix
BASE:

// state of interpreter, 0 = interpret, 1 = compile
STATE:

// link to latest word in dictionary
LATEST:

// dictionary pointer
XDP:

// turn on routine after boot
TURN:

// turn of routine before boot
REST:

// context, where to search a word, reference of vocabulary
CONTXT:

// current, where to create a word, reference of vocabulary
CURTXT:

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
//  Lnk, aka link pointer to caller
//  Wrk, aka self pointer to callee
//
// _inner: 
//

header "ENDS", "ends", F_RESERVED, LEAF

_unnest:
    spull Rsp, Wrk

_next: 
    spull Wrk, Lnk
    beq Lnk, zero, _jump

_nest: 
    spush Rsp, Wrk

_link:
    move Wrk, Lnk
    jal zero, _next

_jump:
    spull Rsp, Lnk   
    jalr zero, Wrk, 0

// at end of primitives    
//      jal zero, _link

//----------------------------------------------------------------------

/*
// vide https://github.com/ScannedInAvian/riscyforth/blob/main/boot.S
*/
//----------------------------------------------------------------------
//   ( -- F | T )
header "KEY?", "keyq", , F_RESERVED, LEAF
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- c )
header "KEY", "key", , F_RESERVED, LEAF
    jal zero, _link

//----------------------------------------------------------------------
//   ( c -- )
header "EMIT", "emit", , F_RESERVED, LEAF
    jal zero, _link

/***********************************************************************

  basic primitives
  all primitives must have a 0x0 at start
  order is critical because beq/bne/blt/bgt does only +/- 2 Mib offsets

***********************************************************************/
//----------------------------------------------------------------------
//   ( -- )
header "NOP", "nop", , F_RESERVED, LEAF
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- FALSE)
header "FALSE", "false", , F_RESERVED, LEAF
    spush Psp, Top 
_isfalse:
    addi Top, zero, FALSE  
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- TRUE)
header "TRUE", "true", , F_RESERVED, LEAF
    spush Psp, Top 
_istrue:
    addi Top, zero, TRUE   
    jal zero, _link

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
header "0=", "zequ"    , F_RESERVED, LEAF
    beq Top, zero, _istrue
    bne Top, zero, _isfalse

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE) xxxx
header "0>", "zgth"    , F_RESERVED, LEAF
    blt zero, Top, _istrue
    bge zero, Top, _isfalse 

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
header "0<", "zlth"    , F_RESERVED, LEAF
    blt Top, zero, _istrue
    bge Top, zero, _isfalse 

//----------------------------------------------------------------------
header "=", "equ", , F_RESERVED, LEAF
    spull Psp, Nos
    beq Top, Nos, _istrue
    bne Top, Nos, _isfalse

//----------------------------------------------------------------------
// (n1 n2 -- n1 > n2)
header ">", "greath", , F_RESERVED, LEAF
    spull Psp, Nos
    blt Top, Nos, _istrue
    bge Top, Nos, _isfalse
    
//----------------------------------------------------------------------
// (n1 n2 -- n1 < n2)
header "<", "lessth", , F_RESERVED, LEAF
    spull Psp, Nos
    blt Nos, Top, _istrue
    bge Nos, Top, _isfalse
    
//----------------------------------------------------------------------
// ( w a -- ) store
header "!", "to", , F_RESERVED, LEAF
    spull Psp, Nos
    sw Top, 0 (Nos)
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( a -- w ) fetch
header "@", "at", , F_RESERVED, LEAF
    lw Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u+v )
header "+", "plus",, F_RESERVED, LEAF
    spull Psp, Nos
    add Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u-v )
header "-", "minus",, F_RESERVED, LEAF
    spull Psp, Nos
    sub Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- w )
header "INVERT", "invert", F_RESERVED, LEAF
    xori Top, Top, -1
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- w )
header "NEGATE", "negate", F_RESERVED, LEAF
    sub Top, zero, Top 
    jal zero, _link

//----------------------------------------------------------------------
// ( v -- v<<1 )
header "2*", "twostar", F_RESERVED, LEAF
    srli Top, Top, 1
    jal zero, _link

//----------------------------------------------------------------------
// ( v -- 1>>v )
header "2/", "twoslash", F_RESERVED, LEAF
    slli Top, Top, 1
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u<<v  )
header "LSHIFT", "lshift", F_RESERVED, LEAF
    spull Psp, Nos
    sll Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- u>>v )
header "RSHIFT", "rshift", F_RESERVED, LEAF
    spull Psp, Nos
    srl Top, Nos, Top
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "AND", "andf", F_RESERVED, LEAF
    spull Psp, Nos
    and Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "OR", "orf", F_RESERVED, LEAF
    spull Psp, Nos
    or Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "XOR", "xorf", F_RESERVED, LEAF
    spull Psp, Nos
    xor Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "NAND", "nandf",, F_RESERVED, LEAF
    spull Psp, Nos
    and Nos, Top, Nos
    neg Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0x20 )
header "BL", "bl", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, BL_
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0x20 )
header "CR", "CR", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, CR_
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0x20 )
header "LF", "LF", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, LF_
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0 )
header "0", "nil", , F_RESERVED, LEAF
    spush Psp, Top 
    add Top, zero, zero
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 1 )
header "1", "one", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, 1
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 2 )
header "2", "two", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, 2
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 4 )
header "4", "four", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, 4
    jal zero, _link

//----------------------------------------------------------------------
// ( -- CELL )
header "CELL", "cell", , F_RESERVED, LEAF
    spush Psp, Top 
    addi Top, zero, CELL
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- u*CELL )
// CELL is 4, multiply by shift left
header "CELLS", "cells", , F_RESERVED, LEAF
    slli Top, Top, 2
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- u+CELL )
// CELL is 4, add a CELL size
header "CELL+", "cellplus", , F_RESERVED, LEAF
    addi Top, Top, CELL
    jal zero, _link

//----------------------------------------------------------------------
// CHAR is one byte, just add zero 
// ( u -- u*BYTE )
// hook 
header "CHARS", "chars", , F_RESERVED, LEAF
    add Top, Top, zero
    jal zero, _link

//----------------------------------------------------------------------
// CHAR is one byte, add a char size
// ( u -- u+BYTE )
header "CHAR+", "charplus", , F_RESERVED, LEAF
    addi Top, Top, BYTE
    jal zero, _link

//----------------------------------------------------------------------
// put at 2nd to preserve the immediate next reference 
header ">R", "tor", , F_RESERVED, LEAF
    spull Rsp, Nos
    spush Rsp, Top
    spush Rsp, Nos
    spull Psp, Top 
    jal zero, _link

//----------------------------------------------------------------------
// get at 2nd to preserve the immediate next reference 
header "R>", "rto", , F_RESERVED, LEAF
    spush Psp, Top 
    spull Rsp, Nos
    spull Rsp, Top 
    spush Rsp, Nos
    jal zero, _link

//----------------------------------------------------------------------
// copy from 2nd to preserve the immediate next reference 
header "R@", "rat", , F_RESERVED, LEAF
    spush Psp, Top 
    lw Top, 1 (Rsp)
    jal zero, _link

//----------------------------------------------------------------------
//   ( rs -- )
header "RP!", "rsto", , F_RESERVED, LEAF
    add Rsp, Top, zero 
    jal zero, _drop
    
//----------------------------------------------------------------------
//   ( ps -- )
header "SP!", "psto", , F_RESERVED, LEAF
    add Psp, Top, zero
    jal zero, _drop

//----------------------------------------------------------------------
//   ( rs -- )
header "RP@", "rsat", , F_RESERVED, LEAF
    spush Psp, Top
    add Top, Rsp, zero 
    jal zero, _drop
    
//----------------------------------------------------------------------
//   ( ps -- )
header "SP@", "psat", , F_RESERVED, LEAF
    spush Psp, Top
    add Top, Psp, zero
    jal zero, _drop

//----------------------------------------------------------------------
//   ( u w -- u )
header "DROP", "drop", , F_RESERVED, LEAF
_drop:
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- w )
header "NIP", "nip", , F_RESERVED, LEAF
    spull Psp, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   ( 0 -- 0 ) (w -- w w)
header "?DUP", "zdup", , F_RESERVED, LEAF
    bne Top, zero, _dup  
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- u w w )
header "DUP", "dup", , F_RESERVED, LEAF
_dup:
    spush Psp, Top 
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- u u w )
header "DIP", "dip", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
_dip:
    spush Psp, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   ( u w -- w u w )
header "TUCK", "tuck", , F_RESERVED, LEAF
    spull Psp, Nos
    spush Psp, Top
    beq zero, zero, _dip

//----------------------------------------------------------------------
//   ( u w -- u w u )
header "OVER", "over", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    spush Psp, Top
_n2t:
    add Top, Nos, zero
    jal zero, _link
    
//----------------------------------------------------------------------
//   ( v u w -- v w u )
header "SWAP", "swap", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    sw Top, 0 (Psp)
    beq zero, zero, _n2t

//----------------------------------------------------------------------
//   (v u w -- u w v)
header "ROT", "rot", , F_RESERVED, LEAF
    lw Wrk, 0 (Psp)
    lw Nos, CELL (Psp)
    sw Wrk, CELL (Psp)
    sw Top, 0 (Psp)
    beq zero, zero, _n2t
    
//----------------------------------------------------------------------
//   (v u w -- w v u)
header "-ROT", "nrot", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    lw Wrk, CELL (Psp)
    sw Top, CELL (Psp)
    sw Wrk, 0 (Psp)
    beq zero, zero, _n2t
    
//----------------------------------------------------------------------
//   (v u w -- w u v)
header "FLIP", "flip", , F_RESERVED, LEAF
    lw Nos, CELL (Psp)
    sw Top, CELL (Psp)
    beq zero, zero, _n2t
    
//----------------------------------------------------------------------
//   ( v u w -- u v w )
header "SWIP", "swip", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    lw Wrk, CELL (Psp)
    sw Nos, CELL (Psp)
    sw Wrk, 0 (Psp)
    jal zero, _link

//----------------------------------------------------------------------
header "MIN", "min", , F_RESERVED, LEAF
    spull Psp, Nos
    blt Top, Nos, _noop 
    beq zero, zero, _n2t
  
//----------------------------------------------------------------------
header "MAX", "max", , F_RESERVED, LEAF
    spull Psp, Nos
    blt Nos, Top, _noop 
    beq zero, zero, _n2t
  
zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz
//----------------------------------------------------------------------
// trick, 
// ????
header "LIT", "lit", , F_RESERVED, LEAF
dolit:
    spush Psp, Top 
    spull Rsp, Top
    jal zero, _link

//----------------------------------------------------------------------
// trick,
// ????
header "EXE", "exe", , F_RESERVED, LEAF
dolit:
    spush Rsp, Top 
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
// trick, branch if Top is zero else skip next reference
header "?BRANCH", "zbranch", , F_RESERVED, LEAF
    beq Top, zero, _branch
    jal zero, _link
    
//----------------------------------------------------------------------
// all absolut reference, no more offsets
header "BRANCH", "branch", , F_RESERVED, LEAF
_branch:    
    spull Rsp, Wrk
    lbu Wrk, 0 (Wrk)
    spush Rsp, Wrk
    jal zero, _link

//----------------------------------------------------------------------
//   ( b a -- ) 
// writes one byte at address, unsigned
header "C!", "cto", , F_RESERVED, LEAF
    spull Psp, Nos
    sb Nos, 0 (Top)
    beq zero, zero, _drop
  
//----------------------------------------------------------------------
//   ( a -- b )
// reads one byte from address, unsigned
header "C@", "cat", , F_RESERVED, LEAF
    lbu Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
//   ( w a --  )
// add to contents of a address
header "+!", "plusto", , F_RESERVED, LEAF
    spull Psp, Nos
    lw Wrk, 0 (Top)
    add Wrk, Wrk, Nos
    sw Wrk, 0 (Top)
    beq zero, zero, _drop
  
//----------------------------------------------------------------------
// from amforth 6.9
//   ( a -- b )
// aligns a address to next CELL
header "ALIGNED", "aligned", , F_RESERVED, LEAF
    andi Wrk, Top, 1
    add Top, Top, Wrk
    andi Wrk, Top, 2 
    add Top, Top, Wrk
    jal zero, _link

/******************************************************************************

    arithmetic functions using riscv instructions

*******************************************************************************/
// -----------------------------------------------------------------------------
// ok multiply ( w1 w2 w3 -- ((w1 * w2) / w3) ) zzzz
header "*/", "starslash", , F_RESERVED, LEAF
    spull Psp, Nos
    mul Top, Top, Nos
    spull Psp, Nos
    div Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok multiply ( w1 w2 -- w1 * w2 )
header "*", "star", , F_RESERVED, LEAF
    spull Psp, Nos
    mul Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
 // ok unsigned multiply ( w1 w2 -- w1 * w2 )
header "m*", "mstar", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    mul Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    mulh Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok unsigned multiply ( w1 w2 -- w1 * w2 )
header "um*", "umstar", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    mul Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    mulhu Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok divide ( w1 w2 -- quotient )
header "/", "slash", , F_RESERVED, LEAF
    spull Psp, Nos
    div Top, Nos, Top
    jal zero, _link

// -----------------------------------------------------------------------------
// ok module ( w1 w2 -- remainder ) 
header "mod", "module", , F_RESERVED, LEAF
    spull Psp, Nos
    rem Top,  Nos, Top
    jal zero, _link

// -----------------------------------------------------------------------------
// ok dual divide ( w1 w2 -- remainder quotient )
header "/mod", "slashmod", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    rem Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    div Top, Top, Nos
    jal zero, _link

// -----------------------------------------------------------------------------
// ok unsigned dual divide  ( w1 w2 -- remainder quotient )
header "u/mod", "uslashmod", , F_RESERVED, LEAF
    lw Nos, 0 (Psp)
    remu Wrk, Top, Nos
    sw Wrk, 0 (Psp)
    divu Top, Top, Nos
    jal zero, _link

/******************************************************************************

    iterative loops

*******************************************************************************/

//----------------------------------------------------------------------
// copy a cell from return stack
// number is  converted to CELLs
// copy a cell index ( n -- R:n )
header "CS-PICK", "cspick", F_COMPILE_ONLY, F_RESERVED, LEAF
    // CELL is 4 bytes
    slli Top, Top, 2 
    add Wrk, Rsp, Top
    lw Top, 0 (Wrk)
    jal zero, _link

//---------------------------------------------------------------------
//   ( a1 a2 u --- )
// move cells (32bit) from a1 source++ to a2 destination++, decrease count--
// returns 0 if equal (no differ)
//
header "MOVE", "move", F_RESERVED, LEAF
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
header "CMOVE", "cmove", F_RESERVED, LEAF
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
header "CMOVE>", "cmoveb", F_RESERVED, LEAF
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
header "CSAME", "csame", F_RESERVED, LEAF
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
header "CFILL", "cfill", F_RESERVED, LEAF
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
//   ( c a1  --- a2 | 0 )
// point next non c
// returns 0 at end of buffer
//
header "cskip", "cskip", F_RESERVED, LEAF
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
//   ( c a1  --- a2 | 0 )
// point next c
// returns 0 at end of buffer
//
header "cscan", "cscan", F_RESERVED, LEAF
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
header "sscan", "sscan", F_RESERVED, LEAF
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
header "sfind", "sfind", F_RESERVED, LEAF
    1:
    // copy cstr address
    scopy Psp, Nos, 0
2:  
    lw Wrk, 0 (Top)     // point to lfa
    beq Wrk, zero, 8f   // end of vocabulary

    lw Top, 0 (Wrk)       // update to link
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
    
    depends on dictionary linked list header structure, F_RESERVED, LEAF

***********************************************************************/
// lfa is the reference link word.

//---------------------------------------------------------------------- 
// ok  ( lfa -- flag )
header  ">FLAGS", "toflags", , F_RESERVED, LEAF
    lb Top, (CELL) (Top)
    jal zero, _link
    
//---------------------------------------------------------------------- 
// ok  ( lfa -- nfa )
header  ">NAME", "toname", , F_RESERVED, LEAF
    lb Top, (CELL+1) (Top)
    jal zero, _link
    
//---------------------------------------------------------------------- 
// ok  ( lfa -- cfa )
header  ">BODY", "tobody", , F_RESERVED, LEAF
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
header "_EOW_", "_eoW_", F_RESERVED, LEAF
    
#include "biosv.S"

#include "words.S"

header "_EOF_", "_eoF_", F_RESERVED, LEAF
    
/*
1       1st     fst,    first
2       2nd     snd,    second
3       3rd     thd,    third
4       4th     fth,    fourth
*/
