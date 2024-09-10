/*
maybeRiscV.md

# RISCV considerations 

Using R32I, 32 bits cell, and same ideias from f2u 
(for atmega8 and exerpts from forth implementations)

Linux free RiscV registers (pointed by LaRs, lbforth)
must be saved by subroutines (calee)
s4 ~X20~ as Ip, return register for BL BR
s5 ~X21~ as Sr, parameter stack pointer
s6 ~X22~ as Rr, return stack pointer
s7 ~X23~ as Tos, Tos work register
s8 ~X24~ as Nos, temporary scratch register
s9 ~X25~ as Wrk, temporary scratch register

https://github.com/riscv-non-isa/riscv-asm-manual/blame/master/riscv-asm.md

The following example shows how to load an absolute address:

    lui  a0, %hi(msg + 1)
    addi a0, a0, %lo(msg + 1)
```
*/

//----------------------------------------------------------------------

/*
.equ FALSE, 0
.equ TRUE, -1
.equ CELL,  4

// as PDP-11, six registers
.equ Ip, s4 //   return register
.equ Rs, s5 //   return stack register
.equ Ps, s6 //   parameter stack register
.equ Tos, s7 //   Top of parameter stack
.equ Nos, s8 //   hold for    
.equ Wrk, s9 //   hold for
// using also s10 and s11 temporary
.equ T0, s10
.equ T1, s11
*/

 #define  FALSE 0
 #define  TRUE -1
 #define  CELL  4

 #define  Ip s4     //   instruction register
 #define  Rs s5     //   return stack register
 #define  Ps s6     //   parameter stack register
 #define  Tos s7     //   Top of parameter stack
 #define  Nos s8     //   hold for
 #define  Wrk s9     //   hold for
 #define  T0 s10    //   temporary
 #define  T1 s11    //   temporary

//----------------------------------------------------------------------
// stack macros
//
.macro rspull reg
    lw \reg, 0(Rs)
    addi Rs, Rs, -1*CELL
.endm

.macro rspush reg
    sw \reg, 0(Rs)
    addi Rs, Rs, CELL
.endm

.macro pspull reg
    lw \reg, 0(Ps)
    addi Ps, Ps, -1*CELL
.endm

.macro pspush reg
    sw \reg, 0(Ps)
    addi Ps, Ps, CELL
.endm

.macro jump address
    jal zero, \address
.endm

//----------------------------------------------------------------------
//
// header of word in dictionary
//   byte flags must be 0x80, 0x40, 0x20, 0x10
//   byte size  must be 1 to 15
//   [link][size+flags][name][pad?]
//
//----------------------------------------------------------------------
//
// set start reverse linked list
//
// adapted from amforth-6.9
.text
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
    .byte (3f - 2f) + \flags
2:
    .ascii "\name"
3:
    .p2align 1, 0x20	
\label:
.endm

//----------------------------------------------------------------------
//
//   forth inner interpreter
//
header "ENDS", "ends"
_ends: 
    .word 0x0

_unnest: // aka do_semis
    rspull Ip

_next: // next
    lw Wrk, 0 (Ip)
    addi Ip, Ip, CELL
    beq Wrk, zero, _jump

_nest:  // aka do_colon
    rspush Ip
    lw Ip, 0 (Wrk)

_link:    
    jal zero, _next

_jump:   
    add Wrk, zero, Ip
    addi Ip, Ip, CELL
    jalr zero, Wrk, 0

//   [ link,size+flags,name,pad?, 0x0, code, (jal zero, link) ]

//   [ link,size+flags,name,pad?, ref, ..., ref ,_ends]

//----------------------------------------------------------------------
// ( -- 0 )
header "0", "zeru", 
    .word 0x0
    pspush Tos 
    add Tos, zero, zero  // li Tos, 0
    jal zero, _link

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
header "0=", "zequ"    
    .word 0x0
    beq Tos, zero, _ftrue
_ffalse:
    addi Tos, zero, FALSE  // li Tos, FALSE
    jal zero, _link
_ftrue:
    addi Tos, zero, TRUE   // li Tos, TRUE
    jal zero, _link

//----------------------------------------------------------------------
// ( w a -- )
header "!", "to", 
    .word 0x0
    pspull Nos
    sw Tos, 0 (Nos)
    pspull Tos 
    jal zero, _link

//----------------------------------------------------------------------
// ( a -- w )
header "@", "at", 
    .word 0x0
    lw Tos, 0 (Tos)
    jal zero, _link

//----------------------------------------------------------------------
// ( -- rsp )
header "RS@", "RSAT",
    .word 0x0
    pspush Tos 
    add Tos, zero, Rs
    jal zero, _link

//----------------------------------------------------------------------
// ( -- psp )
header "PS@", "PSAT",
    .word 0x0
    pspush Tos 
    add Tos, zero, Ps
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "NAND", "nand",
    .word 0x0
    pspull Nos
    and Nos, Tos, Nos
    neg Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "PLUS", "plus",
    .word 0x0
    pspull Nos
    add Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "MINUS", "minus",
    .word 0x0
    pspull Nos
    sub Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "SHR", "shr"
    .word 0x0
    pspull Nos
    srl Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "SHL", "shl"
    .word 0x0
    pspull Nos
    sll Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "AND", "and"
    .word 0x0
    pspull Nos
    and Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "OR", "or"
    .word 0x0
    pspull Nos
    or Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- w )
header "XOR", "xor"
    .word 0x0
    pspull Nos
    xor Tos, Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- w )
header "INVERT", "invert"
    .word 0x0
    xori Tos, Tos, -1
    jal zero, _link

//----------------------------------------------------------------------
// ( u -- w )
header "NEGATE", "negate"
    .word 0x0
    sub Tos, zero, Tos 
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- FALSE)
header "FALSE", "false", 
    .word 0x0
    pspush Tos 
_isfalse:
    addi Tos, zero, FALSE  // li Tos, FALSE
    jal zero, _link

//----------------------------------------------------------------------
//   ( -- TRUE)
header "TRUE", "true", 
    .word 0x0
    pspush Tos 
_istrue:
    addi Tos, zero, TRUE   // li Tos, TRUE
    jal zero, _link

//----------------------------------------------------------------------
header "<", "lt", 
    .word 0x0
    pspull Nos
    blt Tos, Nos, _istrue
    bge Tos, Nos, _isfalse
    
//----------------------------------------------------------------------
header ">", "gt", 
    .word 0x0
    pspull Nos
    blt Nos, Tos, _istrue
    bge Nos, Tos, _isfalse
    
//----------------------------------------------------------------------
header "=", "eq", 
    .word 0x0
    pspull Nos
    beq Tos, Nos, _istrue
    bne Tos, Nos, _isfalse

//----------------------------------------------------------------------
header "<>", "neq", 
    .word 0x0
    pspull Nos
    bne Tos, Nos, _istrue
    beq Tos, Nos, _isfalse

//----------------------------------------------------------------------
header "1", "one", 
    .word 0x0
    pspush Tos 
    addi Tos, zero, 1  // li Tos, 1
    jal zero, _link

//----------------------------------------------------------------------
header "2", "two", 
    .word 0x0
    pspush Tos 
    addi Tos, zero, 2  // li Tos, 2
    jal zero, _link

//----------------------------------------------------------------------
header "CELL", "cell", 
    .word 0x0
    pspush Tos 
    addi Tos, zero, CELL   // li Tos, CELL
    jal zero, _link

//----------------------------------------------------------------------
// CELL is 4, multiply by shift left
header "CELLS", "cells", 
    .word 0x0
    slli Tos, Tos, 2
    jal zero, _link

//----------------------------------------------------------------------
// CELL is 4, add
header "CELL+", "cellp", 
    .word 0x0
    addi Tos, Tos, CELL
    jal zero, _link

//----------------------------------------------------------------------
// CELL is 4, sub
header "CELL-", "cellm", 
    .word 0x0
    addi Tos, Tos, -1*CELL
    jal zero, _link

//----------------------------------------------------------------------
header ">R", "tor", 
    .word 0x0
    rspush Tos 
    pspull Tos 
    jal zero, _link

//----------------------------------------------------------------------
header "R>", "rto", 
    .word 0x0
    pspush Tos 
    rspull Tos 
    jal zero, _link

//----------------------------------------------------------------------
header "@R", "atr", 
    .word 0x0
    pspush Tos 
    lw Tos, 0 (Rs)
    jal zero, _link

//----------------------------------------------------------------------
//   ( rs -- )
header "R!", "rsto", 
    .word 0x0
    add Rs, zero, Tos 
    jal zero, _pull
    
//----------------------------------------------------------------------
//   ( ps -- )
header "P!", "psto", 
    .word 0x0
    add Ps, zero, Tos 
    jal zero, _pull

//----------------------------------------------------------------------
//   ( w -- )
header "DROP", "drop", 
    .word 0x0
_pull:
    pspull Tos 
    jal zero, _link

//----------------------------------------------------------------------
//   ( w -- w w )
header "DUP", "dup", 
    .word 0x0
_push:
    pspush Tos 
    jal zero, _link

//----------------------------------------------------------------------
//   ( w v -- v w )
header "SWAP", "swap", 
    .word 0x0
    pspull Nos
_swap:    
    pspush Tos 
    mv Tos, Nos
    jal zero, _link

//----------------------------------------------------------------------
//   (w v -- w v w)
header "OVER", "over", 
    .word 0x0
    lw Nos, CELL (Ps)
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
    beq Tos, zero, 1f
    pspush Tos 
1:    
    jal zero, _link

//----------------------------------------------------------------------
// trick, load Tos <- (IP)
// used by constant, leaves a value onto Tos, also know as doLit
header "DOCON", "DOCON", 
    .word 0x0
    pspush Tos 
    lw Tos, 0(Ip)
    jal zero, _skip

//----------------------------------------------------------------------
// trick, load Tos <- IP
// used by variable, leaves a reference onto Tos,  
header "DOVAR", "DOVAR", 
    .word 0x0
    pspush Tos 
    add Tos, zero, Ip
    jal zero, _skip

//----------------------------------------------------------------------
// trick, if Tos not zero skip next reference, drop Tos
header "?BRANCH", "zbranch", 
    .word 0x0
    add Wrk, zero, Tos 
    pspull Tos 
    beq Wrk, zero, _branch
_skip:
    addi Ip, Ip, CELL
    jal zero, _link
    
//----------------------------------------------------------------------
// trick, a follow reference is always a offset to branch
header "BRANCH", "branch", 
    .word 0x0
_branch:    
    lw Wrk, 0 (Ip)
    add Ip, Ip, Wrk
    jal zero, _link

//----------------------------------------------------------------------
// trick, a Tos reference is pushed into return stack
header "EXECUTE", "execute", 
    .word 0x0
    rspush Tos 
    jal zero, _pull
    
//  ZZZZ >< ABS ALLIGN 

//----------------------------------------------------------------------
//   ( b a -- ) 
// writes one byte at address, unsigned
header "C!", "cto", 
    .word 0x0
    pspull Nos
    sb Nos, 0 (Tos)
    jal zero, _pull

//----------------------------------------------------------------------
//   ( a -- b )
// reads one byte from address, unsigned
header "C@", "cat", 
    .word 0x0
    lbu Tos, 0 (Tos)
    jal zero, _link

//----------------------------------------------------------------------
//   ( w a --  )
// reads one byte from address
header "+!", "plusto", 
    .word 0x0
    pspull Nos
    lw Wrk, 0 (Tos)
    add Wrk, Wrk, Nos
    sw Wrk, 0 (Tos)
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
    beq Tos, zero, 2f
    lb T0, 0 (Wrk)
    lb T1, 0 (Nos)
    xor T0, T1, T0
    bne T0, zero, 2f

    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    addi Tos, Tos, -1
    jal zero, 1b
2:
    // results
    add Tos, zero, T0
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
    beq Tos, zero, 2f
    lb T0, 0(Wrk)
    sb T0, 0(Nos)
    addi Wrk, Wrk, 1
    addi Nos, Nos, 1
    addi Tos, Tos, -1
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
    add Nos, Nos, Tos 
    add Wrk, Wrk, Tos 
1:
    beq Tos, zero, 2f
    lb T0, 0(Wrk)
    sb T0, 0(Nos)
    addi Wrk, Wrk, -1
    addi Nos, Nos, -1
    addi Tos, Tos, -1
    jal zero, 1b
2:
    jal zero, drop
    
//----------------------------------------------------------------------
HEADER "_EOF_", "_eof_"
