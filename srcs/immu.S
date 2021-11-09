
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
 */

/*
A Forth with extended indirect thread code

# RISCV considerations 

Using R32I, 32 bits cell, 

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
#define  BYTE  1
#define  CELL  4
#define  STACK 18
#define  BUFFER 80

#define  FLASHPAGE 1024    // page of flash memory for flush in GD32VF103CBT6

#define F_IMMEDIATE 0x80
#define F_COMPILE_ONLY 0x40
#define F_HIDDEN  0x20
#define F_TOGGLE  0x10
#define F_COMMON  0x00

F_TOMASK = 0xF0
F_UNMASK = 0x0F

#---------------------------------------------------------------------
# Flow Control
# assumes that all line edit is done at remote!
# no delete, no moving cursor, just a static line.
# works as a screen or block, just receives a line till a CR or CR LF
# uses BS, ESC, CAN, XON, XOFF, for control
#
#define XON_      0x11    #; ascii DC1 ^Q
#define XOFF_     0x13    #; ascii DC3 ^S

#define CR_       0x0d    #; ascci carriage return ^M
#define LF_       0x0a    #; ascii line feed ^J

#define CAN_      0x18    #; ascii cancel ^C
#define ESC_      0x1B    #; ascii escape ^[

#define BS_       0x08    #; ascii backspace ^H
#define TAB_      0x09    #; ascii horizontal ^I
#define BL_       0x20    #; ascii space

#define NUL_      0x00    #; ascii NUL ^@

 
 
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

//----------------------------------------------------------------------
// goto macros
// could have hooks for debugs
//
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

//----------------------------------------------------------------------
.data

// .fill <bytes> reserves and initializes
// .skip <bytes> reserves but dont initialize

VOID:
.word 0x0

// return stack
RSP0:
.fill STACK, CELL, 0x0

//parameter stack
PSP0:
.fill STACK, CELL, 0x0

// terminal input buffer
TIB0:
.fill BUFFER, BYTE, 0x0

// flash buffer for flush
.FIF0:
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

// state of interpreter, 0 = interpret, 1 = compile, 2 = postpone
STATE:
.word 0x0

// link to latest word in dictionary
LATEST:
.word 0x0

// system flags
FLAGS:
.word 0x0

// random seed for random
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
//
// trick adapted from amforth-6.9
99:
.word 0

//----------------------------------------------------------------------
//
header "EXIT", "EXIT"
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
// adapted from https://github.com/ScannedInAvian/riscyforth/blob/main/boot.S

KEY:
    li Wrk, UART_BASE
1:
    lb Nos, 5(Wrk)
    andi Nos, Nos, 0x1
    bequ Nos, zero, 1b

    spull Psp, Top
    lb Top, 0(Wrk)
    jal zero, _link

*/

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
// ( w -- FALSE | TRUE)
header "0>", "zgth"    
    .word 0x0
    blt Top, zero, _istrue
    bge Top, zero, _isfalse 

//----------------------------------------------------------------------
header "=", "eq", 
    .word 0x0
    spull Psp, Nos
    beq Top, Nos, _istrue
    bne Top, Nos, _isfalse

//----------------------------------------------------------------------
header "<", "lt", 
    .word 0x0
    spull Psp, Nos
    blt Top, Nos, _istrue
    bge Top, Nos, _isfalse
    
//----------------------------------------------------------------------
header ">", "gt", 
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
// ( -- rsp )
header "RS@", "rsat",
    .word 0x0
    spush Psp, Top 
    add Top, Rsp, zero
    jal zero, _link

//----------------------------------------------------------------------
// ( -- psp )
header "PS@", "psat",
    .word 0x0
    spush Psp, Top 
    add Top, Psp, zero
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "+", "plus",
    .word 0x0
    spull Psp, Nos
    add Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "-", "minus",
    .word 0x0
    spull Psp, Nos
    add Top, Top, Nos
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
// ( u v -- w >> )
header "SHR", "shr"
    .word 0x0
    spull Psp, Nos
    srl Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w <<  )
header "SHL", "shl"
    .word 0x0
    spull Psp, Nos
    sll Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "AND", "and"
    .word 0x0
    spull Psp, Nos
    and Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "OR", "or"
    .word 0x0
    spull Psp, Nos
    or Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "XOR", "xor"
    .word 0x0
    spull Psp, Nos
    xor Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "NAND", "nand",
    .word 0x0
    spull Psp, Nos
    and Nos, Top, Nos
    neg Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( -- 0 )
header "0", "nil", 
    .word 0x0
    spush Psp, Top 
    add Top, zero, zero  // li Top, 0
    jal zero, _link

//----------------------------------------------------------------------
header "1", "one", 
    .word 0x0
    spush Psp, Top 
    addi Top, zero, 1  // li Top, 1
    jal zero, _link

//----------------------------------------------------------------------
header "2", "two", 
    .word 0x0
    spush Psp, Top 
    addi Top, zero, 2  // li Top, 2
    jal zero, _link

//----------------------------------------------------------------------
header "CELL", "cell", 
    .word 0x0
    spush Psp, Top 
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
header "R!", "rsto", 
    .word 0x0
    add Rsp, Top, zero 
    jal zero, _drop
    
//----------------------------------------------------------------------
//   ( ps -- )
header "P!", "psto", 
    .word 0x0
    add Psp, Top, zero
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
//  beq zero, zero, _dip
    spush Psp, Nos
    jal zero, _link

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
//  beq zero, zero, _n2t
    add Top, Nos, zero
    jal zero, _link

//----------------------------------------------------------------------
//   (v u w -- u w v)
header "ROT", "rot", 
    .word 0x0
    lw Wrk, 0 (Psp)
    lw Nos, CELL (Psp)
    sw Wrk, CELL (Psp)
    sw Top, 0 (Psp)
//  beq zero, zero, _n2t
    add Top, Nos, zero
    jal zero, _link
    
//----------------------------------------------------------------------
//   (v u w -- w v u)
header "-ROT", "nrot", 
    .word 0x0
    lw Nos, 0 (Psp)
    lw Wrk, CELL (Psp)
    sw Top, CELL (Psp)
    sw Wrk, 0 (Psp)
//  beq zero, zero, _n2t
    add Top, Nos, zero
    jal zero, _link
    
//----------------------------------------------------------------------
//   (v u w -- w u v)
header "FLIP", "flip", 
    .word 0x0
    lw Nos, CELL (Psp)
    sw Top, CELL (Psp)
//  beq zero, zero, _n2t
    add Top, Nos, zero
    jal zero, _link
    
//----------------------------------------------------------------------
header "MIN", "min", 
    .word 0x0
    spull Psp, Nos
    blt Top, Nos, _noop 
//  beq zero, zero, _n2t
    add Top, Nos, zero
    jal zero, _link

//----------------------------------------------------------------------
header "MAX", "max", 
    .word 0x0
    spull Psp, Nos
    blt Nos, Top, _noop 
//  beq zero, zero, _n2t
    add Top, Nos, zero
    jal zero, _link

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
// trick, load Top <- (IP)
// used by constant, leaves a value onto Top, also know as doLit
header "DOCON", "DOCON", 
    .word 0x0
    spush Psp, Top 
    lw Top, 0 (Ipt)
_iic:
    addi Ipt, Ipt, CELL
    jal zero, _link

//----------------------------------------------------------------------
// trick, load Top <- IP
// used by variable, leaves a reference onto Top,  
header "DOVAR", "DOVAR", 
    .word 0x0
    spush Psp, Top 
    add Top, Ipt, zero
//  beq zero, zero, _iic
    addi Ipt, Ipt, CELL
    jal zero, _link

//----------------------------------------------------------------------
// trick, if Top not zero skip next reference, drop Top
header "?BRANCH", "zbranch", 
    .word 0x0
    add Wrk, zero, Top 
    spull Psp, Top 
    beq Wrk, zero, _branch
//  beq zero, zero, _iic
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
    spush Rsp, Top 
//  beq zero, zero, _drop    
    spull Psp, Top
    jal zero, _link
    
//  ZZZZ >< ABS 

//----------------------------------------------------------------------
//   ( b a -- ) 
// writes one byte at address, unsigned
header "C!", "cto", 
    .word 0x0
    spull Psp, Nos
    sb Nos, 0 (Top)
//  beq zero, zero, _drop
    spull Psp, Top
    jal zero, _link

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
    spull Psp, Nos
    lw Wrk, 0 (Top)
    add Wrk, Wrk, Nos
    sw Wrk, 0 (Top)
//  beq zero, zero, _drop
    spull Psp, Top
    jal zero, _link

//----------------------------------------------------------------------
//   ( a -- b )
// aligns a address to next CELL
header "ALIGN", "align", 
    .word 0x0
    addi Wrk, Wrk, (CELL - 1)
    add Top, Top, Wrk
    xori Wrk, Wrk, -1 
    and Top, Top, Wrk
    jal zero, _link

//----------------------------------------------------------------------
//   ( a1 a2 u --- FALSE | TRUE )
// compare bytes from source++ to destination++, decrease count--
// returns 0 if equal (no differ)
// used most to compare names with less than 16 of length
// 
header "SAME?", "sameq"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk

    add T0, zero, zero
1:
    beq Top, zero, 2f
    lb T0, 0 (Wrk)
    lb T1, 0 (Nos)
    or T0, T1, T0
    bne T0, zero, 2f

    addi Wrk, Wrk, 1
    addi Nos, Nos, 1

    addi Top, Top, -1
    jal zero, 1b
2:
    // results
    add Top, T0, zero
    jal zero, _link

 //----------------------------------------------------------------------
//   ( a u c --- )
// copy  (c) byte to (a) destination++, decrease (u) count--
//
HEADER "CFILL", "cfill"
    .word 0x0
    spull Psp, Nos
    spull Psp, Wrk
1:
    beq Nos, zero, 2f
    sb Top, 0(Wrk)
    addi Wrk, Wrk, 1
    addi Nos, Nos, -1
    jal zero, 1b
2:
    spull Psp, Top 
    jal zero, drop
   
//----------------------------------------------------------------------
//   ( a1 a2 u --- )
// move bytes from source++ to destination++, decrease count--
// returns 0 if equal (no differ)
//
HEADER "CMOVE", "cmove"
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
    jal zero, 1b
2:
    jal zero, drop

//----------------------------------------------------------------------
HEADER "_EOF_", "_eof_"

/*
1       1st     fst,    first
2       2nd     snd,    second
3       3rd     thd,    third
4       4th     fth,    fourth
*/
