

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
 *  the following conditions:
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
 *  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

;---------------------------------------------------------------------
;
;    A small Forth for ATmega8 
;
;---------------------------------------------------------------------
; dictionary structure 
;
; cell size is a word of 16 bits 
;
; .word  link    link to previous 
; .byte  size    sizeof name OR flags 
; .ascii "name"  name, plus a pad byte with BL (0x32) if size is even 
; .word  param,  many references 
;
;----------------------------------------------------------------------
 
;
; classics 
;
.NOLIST 
.LIST 
 
;----------------------------------------------------------------------
; start of dictionary 
;
 
;----------------------------------------------------------------------
;
; this is the forth inner engine, 
;
; a compound word, aka twig, must end with a reference to ENDS 
;
; a primitive work, aka leaf, must start with NOOP and ends with POON 
;
; the size byte must be masked by: or 0xF0 
;
; memory pointer r30:r31 as Z 
; parameter stack pointer r28:r29 as Y 
; return stack pointer r26:r27 as X 
; top of stack r24:r25 
; nos, temporary next of stack r22:r23 
; wrk, temporary working r20:r21 
;
; _zero_, always zero, keeped by timer0
; _work_, scratch
;
; Can only use LPM to access flash memory ? YES! 
;
; forth: all constants in flash
;
; user: no constants and variables in sdram 
;
; why ? flash memory suports only 10.000 cycles 
;
;----------------------------------------------------------------------
; starts just above sram ends 
;
; use the address to determine if is flash or is sram, above is flash :)
;
.section .text 
.org FORTH_INI
.global forth 
_forth_: 
;----------------------------------------------------------------------
; inner interpreter, 
; it is also a primitive word 
;
; on AVR use Z for access flash
;
;   temporary use zpm, wrk, _word_
;
HEADER "ENDS", "ENDS", F_LEAP
; does nothing and mark as primitive 
    NOOP 
 
; pull ips from rsp 
_unnest:  
    rspull zpm_low, zpm_high 
    ; rjump _next
 
; load w with contents of cell at ips 
_next: 
    pmload wrk_low, wrk_high ; also increments zpm 
 
; if zero (NULL) is a primitive word 
_void:
    cp wrk_low, wrk_high 
    brbs BIT_ZERO, _jump
 
; else is a reference ( 2 extra cycles )
_nest: 
    rspush zpm_low, zpm_high ; push next reference 
    movw zpm_low, wrk_low ; point to this reference 
    rjmp _next 
 
; then jump, for exec it 
_jump: 
    ijmp 
 
; then link, for continue 
_link: 
    rjmp _unnest 
 
;----------------------------------------------------------------------
;
; is ZZZZ, hook for incompleteness 
;
HEADER "ZZZZ", "ZZZZ",
    .word ENDS 
 
;********************************************************************** 
;
;   bios i/O 
;
;----------------------------------------------------------------------
;
; ok ( -- w) 
; beware, it blocks while test if can receive a char 
;
HEADER "KEY", "KEY", F_LEAP
    NOOP 
1: 
    sbis 0x0b, 7 
    rjmp 1b 
2: 
    pspush tos_low, tos_high
    in tos_low, 0x0c 
    clr tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- 0 | w) 
; test if can receive a char, or return FALSE 
;
HEADER "KEY?", "QKEY", F_LEAP
    NOOP 
3: 
    sbis 0x0b, 7 
    rjmp _ffalse 
    rjmp 2b 
 
;----------------------------------------------------------------------
;
; ok ( w -- ) 
; beware, it blocks while test if can send a char 
;
HEADER "EMIT", "EMIT", F_LEAP
    NOOP 
1: 
    sbis 0x0b, 5 
    rjmp 1b 
2: 
    out 0x0c, tos_low 
    pspull tos_low, tos_high
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w 0) 
; test if can send a char, or return FALSE 
;
HEADER "EMIT?", "QEMIT", F_LEAP
    NOOP 
3: 
    sbis 0x0b, 5 
    rjmp _ffalse 
    rjmp 2b 
 
;----------------------------------------------------------------------
;
; ok ( u u w -- ) 
;
HEADER ">EEPROM", "TOEEPROM", F_LEAP
    NOOP 
    pspull nos_low, nos_high

EEPROM_write:
; Wait for completion of previous write
    sbic EECR, EEPE
    rjmp EEPROM_write

; Set up address  in address register
    out EEARH, tos_high
    out EEARL, tos_low
; Write data to Data Register
    out EEDR, nos_low
; prepare    
    in r2, __SREG__
    cli
; Write logical one to EEMPE
    sbi EECR, EEMPE
; Start eeprom write by setting EEPE
    sbi EECR, EEPE
; restore
    out __SREG__, r2
    sei
    POON

;----------------------------------------------------------------------
;
; ok ( w -- u ) 
;
HEADER "EEPROM>", "EEPROMTO", F_LEAP
    NOOP 
    pspull nos_low, nos_high

EEPROM_read:
; Wait for completion of previous write
    sbic EECR, EEPE
    rjmp EEPROM_read
; Set up address in address register
    out EEARH, tos_high
    out EEARL, tos_low
; Start eeprom read by writing EERE
    sbi EECR, EERE
; Read data from Data Register
    in tos_low, EEDR
    clr tos_high
    POON

;----------------------------------------------------------------------
;
; ok ( w -- u ) 
; also io@
;
HEADER "PEEK", "PEEK", F_LEAP
    NOOP 
    movw zpm_low, tos_low  
    ld tos_low, Z
    clr tos_high
    POON

;----------------------------------------------------------------------
;
; ok ( u w -- ) 
; also io!
;
HEADER "POKE", "POKE", F_LEAP
    NOOP 
    movw zpm_low, tos_low  
    st Z, tos_low
    pspull tos_low, tos_high
    POON
    
;----------------------------------------------------------------------
;
; ok ( -- w) 
; push timer counter 
;
HEADER "MILLIS", "MILLIS", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    mov tos_low, ticks_low 
    mov tos_high, ticks_high 
    POON 
 
;********************************************************************** 
;
;   primitive words 
;
;----------------------------------------------------------------------
 
;----------------------------------------------------------------------
;
; ok 0= 
;
HEADER "0=", "ZEQU", F_LEAP
    NOOP 
    cp tos_low, tos_high
    brbs BIT_ZERO, _ftrue
_ffalse:
    clr tos_low 
    clr tos_high 
    POON
_ftrue: 
    ser tos_low 
    ser tos_high 
    POON
 
;----------------------------------------------------------------------
;
; ok ! to (w a -- ) 
; only in sram 
;
HEADER "!", "TO", F_LEAP
    NOOP 
    movw  zpm_low, tos_low
    pspull tos_low, tos_high 
    srsave tos_low 
    srsave tos_high
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok @ at ( a -- w ) 
; only in sram 
;
HEADER "@", "AT", F_LEAP
    NOOP 
    movw zpm_low, tos_low 
    srload tos_low 
    srload tos_high 
    POON
 
;----------------------------------------------------------------------
;
; ok ( -- -1 ) 
;
HEADER "TRUE", "FTRUE", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
_iftrue: 
    ser tos_low 
    ser tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- 0 ) 
;
HEADER "FALSE", "FFALSE", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
_iffalse: 
    clr tos_low 
    clr tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1 ) 
;
HEADER "<", "LTHAN", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    cp tos_low, nos_low 
    cpc tos_high, nos_high 
    brlt _iftrue 
    rjmp _iffalse 
 
;----------------------------------------------------------------------
;
; ok ( w -- ) ( -- W) 
;      
;
HEADER ">R", "TOR", F_LEAP
    NOOP 
    rspush tos_low, tos_high 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- w ) ( w -- ) 
;     
;
HEADER "R>", "RTO", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    rspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- w ) ( w -- w ) 
;
HEADER "R@", "RAT", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    rspull tos_low, tos_high 
    subi psp_low, 2 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( rsp -- ) 
;
HEADER "RS!", "RPTO", F_LEAP
    NOOP 
    movw rsp_low, tos_low 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( psp -- ) 
;
HEADER "PS!", "SPTO", F_LEAP
    NOOP 
    movw psp_low, tos_low 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- rsp) 
; put the address to top of return stack at tos
;
HEADER "RS@", "RPAT", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    movw tos_low, rsp_low 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- psp ) 
; put the address to top of parameter stack at tos
;
HEADER "PS@", "SPAT", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    movw tos_low, psp_low 
    POON 

;----------------------------------------------------------------------
;
; ok ( w -- ) 
;     
;
HEADER "DROP", "DROP", F_LEAP
    NOOP
PULL: 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w w) 
;
HEADER "DUP", "DUP", F_LEAP
    NOOP 
PUSH:
    pspush tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 -- w1 w2 ) 
;
HEADER "SWAP", "SWAP", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    pspush tos_low, tos_high 
    movw tos_low, nos_low
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 -- w2 w1 w2 ) 
;
HEADER "OVER", "OVER", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    pspush nos_low, nos_high 
    pspush tos_low, tos_high 
    movw tos_low, nos_low
    POON 
 
;----------------------------------------------------------------------
;
; ok ( 0 | w -- 0 | w w ) 
; dup if tos not zero 
;
HEADER "?DUP", "ZDUP", F_LEAP
    NOOP 
    cp tos_low, tos_high
    brst BIT_ZERO, 1f 
    pspush tos_low, tos_high 
1: 
    POON 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 + w1 ) 
;
HEADER "+", "PLUS", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    clc 
    add tos_low, nos_low 
    adc tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 - w1 ) 
;
HEADER "-", "MINUS", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    clc 
    sub tos_low, nos_low 
    sbc tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 NAND w1 ) 
;
HEADER "NAND", "NAND", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    and tos_low, nos_low 
    and tos_high, nos_high 
    com nos_low 
    com nos_high 
    POON 

;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 AND w1 ) 
;
HEADER "AND", "AND", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    and  tos_low, nos_low 
    and  tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 OR w1 ) 
;
HEADER "OR", "OR", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    or   tos_low, nos_low 
    or   tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 XOR w1 ) 
;
HEADER "XOR", "XOR", F_LEAP
    NOOP 
    pspull nos_low, nos_high 
    eor  tos_low, nos_low 
    eor  tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok INV 
;
HEADER "INVERT", "INVERT", F_LEAP
    NOOP 
_inv: 
    com tos_low 
    com tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok NEG 
;
HEADER "NEGATE", "NEGATE", F_LEAP
    NOOP 
_neg: 
    neg tos_low 
    neg tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w * 2 ) same as shift left << 1, unsigned 
;
HEADER "2*", "SHL", F_LEAP
    NOOP 
_shl: 
    clc 
    lsl   tos_low 
    rol   tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w / 2 ) same as shift right >> 1, unsigned 
;
HEADER "2/", "SHR", F_LEAP
    NOOP 
_shr: 
    clc 
    lsr tos_low 
    ror tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( nAnB -- nBnA ) swap bytes in a word 
;
HEADER "><", "ENDIAN", F_LEAP
    NOOP 
    mov wrk_low, tos_low
    mov tos_low, tos_high
    mov tos_high, wrk_low
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- ) ( branch next reference ) 
; doing offsets in bytes 
;
HEADER "BRANCH", "BRANCH", F_LEAP
    NOOP 
_branch: 
    rspull zpm_low, zpm_high 
    pmload nos_low, nos_high 
    sbiw zpm_low, 2
    add zpm_low, nos_low 
    adc zpm_high, nos_high 
    rspush zpm_low, zpm_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( u -- ) 
; branch IF tos IS zero 
;
HEADER "?BRANCH", "ZBRANCH", F_LEAP
    NOOP 
    movw nos_low, tos_low
    pspull tos_low, tos_high
    cp nos_low, nos_high
    brbs BIT_ZERO, _branch 
    ; skips forward
    rspull zpm_low, zpm_high 
    adiw zpm_low, 2 
    rspull zpm_low, zpm_high 
    POON 
 
;----------------------------------------------------------------------
;
;  ok DOCON ( -- w ), 
;  push a value from flash to data stack 
;   also DOLIT
;
HEADER "DOCON", "DOCON", F_LEAP
    NOOP 
    pspush tos_low, tos_high
    rspull zpm_low, zpm_high
    pmload tos_low, tos_high 
    rspush zpm_low, zpm_high
    POON 
 
;----------------------------------------------------------------------
;
;  ok DOVAR ( -- w ),  
;  push a reference from flash to data stack 
;
HEADER "DOVAR", "DOVAR", F_LEAP
    NOOP 
    pspush tos_low, tos_high
    rspull tos_low, tos_high
    adiw tos_low, 2
    rspush tos_low, tos_high
    sbiw tos_low, 2
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w ) 
;  data space pointer align to CELL, atmega is always 
 
;
HEADER "ALIGN", "ALLIGN", F_LEAP
    NOOP 
    adiw tos_low, 1 
    cbr tos_low, 0 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- CELL ) 
; CELL is 2 ; size of a cell 
;
HEADER "CELL", "CELL", F_LEAP
    NOOP 
    pspush tos_low, tos_high
    ldi tos_low, CELL_SIZE 
    clr tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok C! ( c a -- ) 
; only works in sram
;
HEADER "C!", "CTO", F_LEAP
    NOOP 
    movw zpm_low, tos_low
    pspull tos_low, tos_high
    st Z, tos_low
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok C@ ( a -- c ) 
; only works in sram
;
HEADER "C@", "CAT", F_LEAP
    NOOP 
    movw zpm_low, tos_low
    ld tos_low, Z
    clr tos_high
    POON 
 
;----------------------------------------------------------------------
;
; ok ( a1 a2 u -- 0 | 1) 
; compare u bytes from source++ to destination++, decrease count--
; returns 0 if equal (no differ) 
; only works in sram
;
HEADER "CSAME", "CSAME", F_LEAP
    NOOP 
    ; WARNING No bound check and counter equal 0 moves nothing 
 
    ; pull address source 
    pspull zpm_low, zpm_high 
 
    ; pull address destin 
    pspull nos_low, nos_high 
 
    ; no offset 
 
    ; free Y
    rspush psp_low, psp_high
    movw psp_low, nos_low

1: 
    mov _work_, tos_low
    or _work_, tos_high
    brbs BIT_ZERO, 2f
 
    ld wrk_low, Y+ 
    ld wrk_high, Z+ 
    or wrk_low, wrk_high 
    brbc BIT_ZERO, 3f 
 
    ; again 
    sbiw tos_low, 1
    rjmp 1b 
 
2: 
    ; equal 
    clr wrk_low 
    clr wrk_high 
    rjmp 4f 
3: 
    ; not equal 
    ser wrk_low 
    ser wrk_high 
4: 
    ; pull psp 
    rspull psp_low, psp_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( s d u -- ) 
; move (forward) copy u bytes from source++ to destination++, decrease count--
; only works in sram
;
HEADER "CMOVE", "MOVEF", F_LEAP
    NOOP 
    ; WARNING No bound check and counter equal 0 moves nothing 
 
    ; pull address source 
    pspull zpm_low, zpm_high 
 
    ; pull address destin 
    pspull nos_low, nos_high 
 
    ; free Y
    rspush psp_low, psp_high
    movw psp_low, nos_low

    ; no offset 
 
1: 
    mov _work_, tos_low
    or _work_, tos_high
    brbs BIT_ZERO, 2f
 
    ; move a cell 
    ld _work_, Y+ 
    st Z+, _work_ 
 
    ; again 
    sbiw tos_low, 1
    rjmp 1b 
 
2: 
    ; pull psp 
    rspull psp_low, psp_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( s d u -- ) 
; move (backward) copy bytes from source-- to destination--, decrease count--
; only works in sram
;
HEADER "CMOVE>", "MOVEB", F_LEAP
    NOOP 
    ; WARNING No bound check and counter equal 0 moves nothing 
 
    ; pull address source 
    pspull zpm_low, zpm_high 
 
    ; pull address destin 
    pspull nos_low, nos_high 
 
    ; free Y
    rspush psp_low, psp_high
    movw psp_low, nos_low

    ; do offset
    add zpm_low, tos_low
    adc zpm_high, tos_high
    add psp_low, tos_low
    adc psp_high, tos_high
 
    ; move a byte
1:
    mov _work_, tos_low
    or _work_, tos_high
    brbs BIT_ZERO, 2f
 
    ld _work_, -Y
    st -Z, _work_

    ; again 
    sbiw tos_low, 1
    rjmp 1b 

2:
    ; pull psp
    rspull psp_low, psp_high
    POON

;----------------------------------------------------------------------
;
; ok ( -- 0 ) 
;
HEADER "0", "ZERO", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    clr tos_low 
    clr tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- 1 ) 
;
HEADER "1", "ONE", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    clr tos_low 
    clr tos_high 
    inc tos_low
    POON 

;----------------------------------------------------------------------
;
; ok ( -- 0 ) 
;
HEADER "2", "TWO", F_LEAP
    NOOP 
    pspush tos_low, tos_high 
    clr tos_low 
    clr tos_high 
    adiw tos_low, 2
    POON 
 
;********************************************************************** 
; FORTH
;
;    the follow definitions of compound words 
;    are as already compiled into a list of references, 
;    that is a sequence of cells. 
;    No preorder because the assembler does translation 
;    of names to address (references) 
;
;    (some adapted from old fig-forth listings) 
;
;********************************************************************** 
;
;    load variables 
;
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "TIB", "TIB",
    .word DOCON, TIB0, ENDS
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "LATEST", "LATEST",
    .word DOVAR, LIST, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "STATE", "STATE",
    .word DOVAR, STAT, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "BASE", "BASE",
    .word DOVAR, BASE, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "(sram)", "sram_",
    .word DOVAR, LAST, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "(eeprom)", "eeprom_",
    .word DOVAR, KEEP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "(flash)", "flash_",
    .word DOVAR, HEAP, ENDS
 
;----------------------------------------------------------------------
;
; is HERE 
;
HEADER "HERE", "HERE",
    .word HEAP, AT, ENDS 
 
;----------------------------------------------------------------------
;
; is ALLOT 
;
HEADER "ALLOT", "ALLOT",
    .word HEAP, PLUSTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 -- w1 ) 
;
HEADER "NIP", "NIP",
    .word SWAP, DROP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 -- w2 w3 w1 ) 
;
HEADER "SWIP", "SWIP",
    .word TOR, SWAP, RTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 -- w2 w1 w2 ) 
;
;HEADER "OVER", "OVER",
;    .word TOR, DUP, RTO, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 -- w2 w1 w3 ) 
;
HEADER "ROT", "ROTU",
    .word SWIP, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 -- w1 w3 w2 ) 
;
HEADER "-ROT", "ROTD",
    .word SWAP, SWIP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 --  w1 w2 w1 ) 
;
HEADER "TUCK", "TUCK",
    .word DUP, SWIP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 --  w1 w2 w3 ) 
;
HEADER "FLIP", "FLIP",
    .word SWAP, SWIP, SWAP, ENDS 

;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1) 
;
HEADER "=", "EQUAL",
    .word MINUS, ZEQU, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1) 
;
HEADER "<>", "NOTEQUAL",
    .word EQUAL, INVERT, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1 ) 
;
HEADER ">", "GTHAN",
    .word SWAP, LTHAN, ENDS 
 
;----------------------------------------------------------------------
;  ok 0>  must be signed 
;
HEADER "0>", "ZEROGT",
     .word ZERO, LTHAN, ENDS 
 
;----------------------------------------------------------------------
;  ok 0< must be signed 
;
HEADER "0<", "ZEROLT",
    .word ZERO, SWAP, LTHAN, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w * CELL  ) 
; CELL is 2, multiply by 2, easy way 
;
HEADER "CELLS", "CELLS",
    .word SHL, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + CELL ) 
;
HEADER "CELL+", "CELLPLUS",
    .word CELL, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - CELL ) 
;
HEADER "CELL-", "CELLMINUS",
    .word CELL, MINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + 1 ) 
;
HEADER "1+", "ONEPLUS",
     .word ONE, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - 1 ) 
;
HEADER "1-", "ONEMINUS",
     .word ONE, MINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + 2 ) 
;
HEADER "2+", "TWOPLUS",
     .word TWO, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - 2 ) 
;
HEADER "2-", "TWOMINUS",
     .word TWO, MINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( u w -- ) 
;
HEADER "+!", "PLUSTO",
    .word SWAP, OVER, AT, PLUS, SWAP, TO, ENDS 
 
;----------------------------------------------------------------------
;
; ok COMMMA ( w -- ) 
;
HEADER ",", "COMMA",
    .word HERE, TO, CELL, ALLOT, ENDS 
 
;----------------------------------------------------------------------
;
; ok this puts next cell into stack and compiles into HERE 
;
HEADER "COMP", "COMP",
    .word DOCON, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok compile a eow 
;
HEADER "EXIT", "EXIT",
    .word COMP, ENDS, ENDS

;----------------------------------------------------------------------
;
; ok compile a eow 
;
HEADER "EXEC", "EXEC",
    .word TOR, ENDS

;----------------------------------------------------------------------
;
; ok compile a eow 
;
HEADER "TAIL", "TAIL",
    .word RAT, CELL, MINUS, RTO, ENDS

;----------------------------------------------------------------------
;
; ok TOBACK 
;
HEADER "TOBACK", "TOBACK", F_IMMEDIATE,
    .word HERE, SWAP, MINUS, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok MARKTO 
;
HEADER "MARKTO", "MARKTO", F_IMMEDIATE,
    .word HERE, DOCON, 0x0000, ENDS 
 
;----------------------------------------------------------------------
;
; ok BEGIN 
;
HEADER "BEGIN", "BEGIN", F_IMMEDIATE,
    .word HERE, ENDS 
 
;----------------------------------------------------------------------
;
; ok AGAIN resolves a backward branch 
;
HEADER "AGAIN", "AGAIN", F_IMMEDIATE,
    .word COMP, BRANCH, TOBACK, ENDS 
 
;----------------------------------------------------------------------
;
; ok UNTIL 
;
HEADER "UNTIL", "UNTIL", F_IMMEDIATE,
    .word COMP, ZBRANCH, TOBACK, ENDS 
 
;----------------------------------------------------------------------
;
; ok UNLESS 
;
HEADER "UNLESS", "UNLESS", F_IMMEDIATE,
    .word INVERT, UNTIL, ENDS 
 
;----------------------------------------------------------------------
;
; ok IF 
;
HEADER "IF", "IF", F_IMMEDIATE,
    .word COMP, ZBRANCH, MARKTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok ENDIF resolves a forward branch 
; note: use of store if addres is not 'here' 
;
HEADER "ENDIF", "ENDIF", F_IMMEDIATE,
    .word DUP, HERE, MINUS, SWAP, TO, ENDS 
 
;----------------------------------------------------------------------
;
; ok THEN 
;
HEADER "THEN", "THEN", F_IMMEDIATE,
    .word ENDIF, ENDS 
 
;----------------------------------------------------------------------
;
; ok ELSE 
;
HEADER "ELSE", "ELSE", F_IMMEDIATE,
    .word COMP, BRANCH, MARKTO, SWAP, ENDIF, ENDS 
 
;----------------------------------------------------------------------
;
; ok WHILE 
;
HEADER "WHILE", "WHILE", F_IMMEDIATE,
    .word IF, ENDS 
 
;----------------------------------------------------------------------
;
; ok REPEAT 
;
HEADER "REPEAT", "REPEAT", F_IMMEDIATE,
    .word TOR, TOR, AGAIN, RAT, RAT, MINUS, ENDIF, ENDS 
 
;----------------------------------------------------------------------
;
; is HOOK 
;
HEADER "HOOK", "HOOK", F_IMMEDIATE,
    .word HERE, TOR, ENDS 
 
;----------------------------------------------------------------------
;
; is BACK 
;
HEADER "BACK", "BACK", F_IMMEDIATE,
    .word COMP, BRANCH, RTO, HERE, SWAP, MINUS, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; is FOR ( u -- ) R:( -- h u )
;
HEADER "FOR", "FOR", 
    .word HERE, TOR, TOR, ENDS 
 
;----------------------------------------------------------------------
;
; is NEXT ( -- ) R:( -- h u ) 
;
HEADER "NEXT", "NEXT",
    .word RTO, ONEMINUS, IF, RTO, DROP, 
    .word ELSE, RAT, SWAP, TOR, TOR, THEN, ENDS 
 
;----------------------------------------------------------------------
;
; DO and LOOP runs from 0x8000 till 0x7FFF, -32768 to 32767
; counting from 0 to 65535, as Forth-83
; ZZZZ
;
;----------------------------------------------------------------------
;
; ok DO (Forth-83)
;
HEADER "DO", "DO", F_IMMEDIATE,
    .word HERE, TOR, 0x8000, PLUS, DUP, TOR, MINUS, TOR, ENDS 
 
;----------------------------------------------------------------------
;
; ok DONT (not Forth-83)
;
HEADER "DONT", "DONT", F_IMMEDIATE,
    .word DROP, DROP, HERE, ENDS 
 
;----------------------------------------------------------------------
;
; is QDO ( u n -- ) (Forth-83)
;
HEADER "QDO", "QDO", F_IMMEDIATE,
    .word OVER, OVER, MINUS, COMP, ZBRANCH, HERE, DO, ENDS 
 
;----------------------------------------------------------------------
;
; ok LOOP (Forth-83)
;
HEADER "LOOP", "LOOP", F_IMMEDIATE,
    .word RAT, ONEPLUS, ZBRANCH, ZZZZ 
    .word RPAT, CELL, MINUS, CELL, MINUS
    .word ENDS 
 
;----------------------------------------------------------------------
;
; ok LEAVE (Forth-83)
;
HEADER "LEAVE", "LEAVE", F_IMMEDIATE,
    .word RTO, RTO, MINUS, ZZZZ, ENDS 
 
;--------------------------------------------------------------------
;
;----------------------------------------------------------------------
;
HEADER "COLD", "COLD", F_LEAP
    NOOP 

; restart return stack 
    ldi rsp_low, lo8(RS0) 
    ldi rsp_high, hi8(RS0) 

; restart parameter stack 
    ldi psp_low, lo8(PS0) 
    ldi psp_high, hi8(PS0) 

; preload to WARM 
    ; next word 
    ldi zpm_low, lo8(WARM) 
    ldi zpm_high, hi8(WARM) 
    rspush zpm_low, zpm_high 
    POON 
 
;----------------------------------------------------------------------
;
HEADER "WARM", "WARM", F_LEAP
    NOOP 
    ; verify error code 
    ; resets etc 
    POON 
 
;----------------------------------------------------------------------
; does reset 
;
HEADER "BYE", "BYE", F_LEAP
    NOOP 
    rjmp RESET 
    POON 

;----------------------------------------------------------------------
;
; is \]  
;
HEADER "]", "RBRAC",
    .word ONE, STATE, TO, ENDS 
 
;----------------------------------------------------------------------
;
; is \[ 
;
HEADER "[", "LBRAC", F_IMMEDIATE
    .word ZERO, STATE, TO, ENDS 
 
;----------------------------------------------------------------------
;
; is TOGGLE ( a f -- )
;
HEADER "TOGGLE", "TOGGLE",
    .word OVER, AT, XOR, SWAP, TO, ENDS 
 
;----------------------------------------------------------------------
;
; is >NFA ( a f -- )
; from link to c_name
;
HEADER ">NFA", "TONFA",
    .word CELL, PLUS, ENDS

;----------------------------------------------------------------------
;
; is >CFA ( a f -- )
; from link to code
HEADER ">CFA", "TOCFA", 
    .word CELL, PLUS, DUP, AT, F_UNMASK, AND, PLUS, ENDS

;----------------------------------------------------------------------
;
; is HIDDEN 
;
HEADER "HIDDEN", "HIDDEN",
    .word LATEST, TONFA, F_HIDDEN, TOGGLE, ENDS 

;----------------------------------------------------------------------
;
; is IMMEDIATE 
;
HEADER "IMMEDIATE", "IMMEDIATE", 
    .word LATEST, TONFA, F_IMMEDIATE, TOGGLE, ENDS 

;----------------------------------------------------------------------
;
; is COMPILE_ONLY 
;
HEADER "COMPILE_ONLY", "COMPILE_ONLY",
    .word LATEST, TONFA, F_COMPILE, TOGGLE, ENDS 

;----------------------------------------------------------------------
;
; is compile a codeptr xt 
;
HEADER "POSTPONE", "POSTPONE", F_IMMEDIATE
    .word FIND, COMMA, ENDS

;----------------------------------------------------------------------
;
; is compile a header 
;
HEADER "CREATE", "CREATE",
    .word ENDS

;----------------------------------------------------------------------
;
; is gets a cc<chars>cc from source
;   ( -- a n )
;
HEADER "PARSE", "PARSE"
    .word ENDS

;----------------------------------------------------------------------
;
; is compile a header 
;
HEADER "FIND", "FIND",
    .word ENDS

;----------------------------------------------------------------------
;
; is  
;
HEADER ":", "COLON",
    .word CREATE, RBRAC, ENDS 
 
;----------------------------------------------------------------------
;
; is  
;
HEADER ";", "SEMMI",
    .word EXIT, LBRAC, ENDS 
  

;----------------------------------------------------------------------
;
; is  
;
;HEADER "INTERPRET", "INTERPRET",
;    .word WORD, DUP2, FIND, DUP, QBRANCH, notfound
;    .word LINK2XT, NIP, NIP, EXECUTE, BRANCH, INTERPRET
;notfound:    
;    .word DROP, DUP2, TONUMBER, QBRANCH, notnumber
;    .word NIP, NIP, BRANCH, INTERPRET
;notnumber:
;    .word EUNDEFI, AT, EXECUTE, BRANCH, INTERPRET
;    .word ENDS
;  
