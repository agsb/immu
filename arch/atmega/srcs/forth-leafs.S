
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
;    A small Forth for ATmega8, ATmega328 
;
;---------------------------------------------------------------------
; dictionary structure 
;
; cell size is a word of 16 bits 
;
; .word  link    link to previous 
; .byte  size    sizeof name (1..15) OR flags 
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
; a primitive work, aka leaf, ends with POON 
;
; the size byte must be masked by: or 0xF0 
;
; memory pointer r30:r31 as Z 
; parameter stack pointer r28:r29 as Y 
; return stack pointer r26:r27 as X 
; top of stack r24:r25 
; nos, temporary next of stack r22:r23 
; wrk, temporary working r20:r21 
; ipt, instruction pointer r18:r19 
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
__forth__: 

;----------------------------------------------------------------------
; inner interpreter, 
; it is also a primitive word 
;
; on AVR use Z for access flash
;
;   temporary use zpm, wrk, _word_
;
HEADER "ENDS", "ENDS", F_LEAP | F_CORE
; does nothing and mark as primitive 
    NOOP 
 
; zzzzzz

; pull ips from rsp 
_unnest:  
    rspull zpm_low, zpm_high 
    ; rjump _next
 
; load w with contents of cell at ips 
_next: 
    pmload wrk_low, wrk_high ; also increments zpm 
 
; if bellow _init_ is a primitive word 
_pick:
    cp mov _work_, wrk_low 
    or _work_, wrk_high 
    brbs BIT_ZERO, _jump

; else is a reference ( 2 extra cycles )
_nest: 
    rspush zpm_low, zpm_high ; push next reference 
    movw zpm_low, wrk_low ; point to this reference 
    rjmp _next 
 
; then jump, for exec it 
_jump: 
   
    mov
    ijmp 
 
; then link, for continue 
_link: 
    rjmp _unnest 
 
;----------------------------------------------------------------------
;
; ok ( -- ) 
;
HEADER "NOOP", "NO_OP", F_LEAP 
    NOOP
    POON

;********************************************************************** 
;
;   bios i/O 
;
;----------------------------------------------------------------------
;
; ok ( -- w) 
; beware, it blocks while test if can receive a char 
;
HEADER "KEY", "KEY", F_LEAP | F_CORE
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
; ok ( -- FALSE | TRUE ) 
; test if can receive a char, or return FALSE 
;
HEADER "KEY?", "QKEY", F_LEAP | F_CORE
    NOOP 
3: 
    sbis 0x0b, 7 
    rjmp _iffalse 
    rjmp _iftrue 
 
;----------------------------------------------------------------------
;
; ok ( w -- ) 
; beware, it blocks while test if can send a char 
;
HEADER "EMIT", "EMIT", F_LEAP | F_CORE
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
; ok ( -- FALSE | TRUE ) 
; test if can send a char, or return FALSE 
;
HEADER "EMIT?", "QEMIT", F_LEAP | F_CORE
    NOOP 
3: 
    sbis 0x0b, 5 
    rjmp _iffalse 
    rjmp _iftrue 
 
;----------------------------------------------------------------------
;
; ok ( c e -- ) 
;   pull up port 
;   zzzz
;
HEADER "PULLUP!", "PUPTO", F_LEAP 
    NOOP 
    POON

;----------------------------------------------------------------------
;
; ok ( c e -- ) 
;   pull down port 
;   zzzz
;
HEADER "PULLDN!", "PDNTO", F_LEAP 
    NOOP 
    POON

;----------------------------------------------------------------------
;
; ok ( c e -- ) 
;   write a byte to eprom 
;
HEADER "EC!", "ECTO", F_LEAP 
    NOOP 
    pspull nos_low, nos_high

_ee_write:
; Wait for completion of previous write
    sbic EECR, EEWE
    rjmp _ee_write

; Set up address  in address register
    out EEARH, tos_high
    out EEARL, tos_low

; Write data to Data Register
    out EEDR, nos_low

; prepare    
    cli
    in r2, __SREG__

; Write logical one to EEMPE
    sbi EECR, EEMWE
; Start eeprom write by setting EEWE
    sbi EECR, EEWE

; restore
    out __SREG__, r2
    sei
    POON

;----------------------------------------------------------------------
;
; ok ( e -- u ) 
;   read eeprom
;
HEADER "EC@", "ECAT", F_LEAP
    NOOP 
    pspull nos_low, nos_high

_ee_read:
; Wait for completion of previous write
    sbic EECR, EEWE
    rjmp _ee_read

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
; only sram
;
HEADER "PC@", "PCAT", F_LEAP 
    NOOP 
_peek:
    movw zpm_low, tos_low  
    ld tos_low, Z
    clr tos_high
    POON

;----------------------------------------------------------------------
;
; ok ( u w -- ) 
; also io!
; only sram
;
HEADER "PC!", "PCTO", F_LEAP
    NOOP
_poke:
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
 
/*
;----------------------------------------------------------------------
;
; ok ( -- w) 
; strat watchdog 
;
HEADER "WDCLR", "WDCLR", F_LEAP 
    NOOP 
    wdr
    POON

HEADER "WDON", "WDON", F_LEAP
    NOOP 
    in r16, WDTCR
    ori r16, (WDE)|(WDP2)|(WDP1)|WDP0)
    out WDTCR, r16
    POON

HEADER "WDOFF", "WDOFF", F_LEAP
    NOOP 
	wdr
    in r16, WDTCR
    ori r16, (WDTOE)|(WDE)
    out WDTCR, r16
    clr r16
    out WDTCR, r16
    POON
*/

;********************************************************************** 
;
;   primitive words 
;
;----------------------------------------------------------------------
 
;----------------------------------------------------------------------
;
; ok ( -- -1 ) 
;
HEADER "TRUE", "FTRUE", F_LEAP | F_CORE
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
HEADER "FALSE", "FFALSE", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
_iffalse: 
    clr tos_low 
    clr tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok 0= 
;
HEADER "0=", "ZEQU", F_LEAP | F_CORE
    NOOP 
    or tos_low, tos_high
    brbs BIT_ZERO, _iftrue
    brbc BIT_ZERO, _iffalse
    POON
 
;----------------------------------------------------------------------
;
; ok 0< 
;   using 2's complement, negative always have 0x8000
HEADER "0<", "ZLTH", F_LEAP | F_CORE
    NOOP 
    ; 0x80
    andi tos_high, 0x80
    brbc BIT_ZERO, _iftrue
    brbs BIT_ZERO, _iffalse
    POON

;----------------------------------------------------------------------
;
; ok ( u1 u2 -- f ) 
;   unsigned lessthan 
;   if u1 < u2, true, else, false
;
HEADER "U<", "UMLESS", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    clc 
    cp  nos_low, tos_low 
    cpc nos_high, tos_high 
1:    
    brlt 2f 
    rjmp _iffalse
2:
    rjmp _iftrue
    POON

;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 c ) 
;   unsigned plus 
;
HEADER "UM+", "UMPLUS", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    clc 
    add tos_low, nos_low 
    adc tos_high, nos_high 
    pspush tos_low, tos_high
    ; preserve carry
1:
    clr tos_high
    clr tos_low
2:    
    brcc 3f
    inc tos_low
3:
    POON 
 
;----------------------------------------------------------------------
;
; ok ! to (w a -- ) 
; only in sram 
;
HEADER "!", "TO", F_LEAP | F_CORE
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
HEADER "@", "AT", F_LEAP | F_CORE
    NOOP 
    movw zpm_low, tos_low 
    srload tos_low 
    srload tos_high 
    POON
 
;----------------------------------------------------------------------
;
; ok @@ at ( a -- a' ) 
; only in flash, fetches a reference to sram 
;	that could be used by @ and ! 
;
HEADER "@@", "ATAT", F_LEAP 
    NOOP 
    movw zpm_low, tos_low
    pmload tos_low, tos_high
	POON
    
;----------------------------------------------------------------------
; 
; Note on return stack operations:
;
;   the values in ( >R R@ R> ) are placed onto/from second cell of return stack.
;
;   this keeps the adjacent reference for inner interpreter, "where it comes" 
;
;   that's a side effect of MITC, there is no IP keeped.
;
;   that's transparent for user.

;----------------------------------------------------------------------
;
; ok ( w -- ) ( -- w) 
;   vide note above
;
HEADER ">R", "TOR", F_COMPILE | F_LEAP | F_CORE
    NOOP 
    rspull nos_low, nos_high
    rspush tos_low, tos_high 
    rspush nos_low, nos_high
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- w ) ( w -- ) 
;   vide note above
;
HEADER "R>", "RTO", F_COMPILE | F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    rspull nos_low, nos_high
    rspull tos_low, tos_high 
    rspush nos_low, nos_high
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- w ) ( w -- w ) 
;   vide note above
;
HEADER "R@", "RAT", F_COMPILE | F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    rspull nos_low, nos_high
    rspull tos_low, tos_high 
    rspush tos_low, tos_high 
    rspush nos_low, nos_high
    POON 
 
;----------------------------------------------------------------------
;
; ok ( rsp -- w )  
;
HEADER "RS!", "RSTO", F_LEAP | F_CORE
    NOOP 
    movw rsp_low, tos_low 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( psp -- w ) 
;
HEADER "PS!", "PSTO", F_LEAP | F_CORE
    NOOP 
    movw psp_low, tos_low 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- rsp) 
; put the address to top of return stack at tos
;
HEADER "RS@", "RSAT", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    movw tos_low, rsp_low 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- psp ) 
; put the address to top of parameter stack at tos
;
HEADER "PS@", "PSAT", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    movw tos_low, psp_low 
    POON 

;----------------------------------------------------------------------
;
; ok ( w -- ) 
;     
;
HEADER "DROP", "DROP", F_LEAP | F_CORE
    NOOP
PULL: 
    pspull tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w w) 
;
HEADER "DUP", "DUP", F_LEAP | F_CORE
    NOOP 
PUSH:
    pspush tos_low, tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w2 w1 ) 
;
HEADER "SWAP", "SWAP", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high ; w1
    pspush tos_low, tos_high ; w2
    movw tos_low, nos_low    ; w1
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w1 w2 w1 ) 
;
HEADER "OVER", "OVER", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high ; w1
    pspush nos_low, nos_high ; w1
    pspush tos_low, tos_high ; w2
    movw tos_low, nos_low    ; w1
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 -- w2 w3 w1 ) 
;
HEADER "ROT", "ROT", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high ; w2
    pspull wrk_low, wrk_high ; w1
    pspush nos_low, nos_high ; w2
    pspush tos_low, tos_high ; w3
    movw tos_low, wrk_low    ; w1
    POON

;----------------------------------------------------------------------
;
; ok ( 0 | w -- 0 | w w ) 
; dup if tos not zero 
;
HEADER "?DUP", "ZDUP", F_LEAP | F_CORE
    NOOP 
    or tos_low, tos_high
    brbs BIT_ZERO, 1f 
    pspush tos_low, tos_high 
1: 
    POON 

;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1 ) ; w2 < w1
;   
HEADER "<", "LTHAN", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    cp tos_low, nos_low 
    cpc tos_high, nos_high 
    brlt 1f 
    rjmp _iffalse
1:
    rjmp _iftrue
    POON
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 ) ; w3 = w1 + w2
;   signed plus
;
HEADER "+", "PLUS", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    clc 
    add tos_low, nos_low 
    adc tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 ) ; w3 = w1 - w2 
;   signed minus, 0 5 -- -5
;
HEADER "-", "MINUS", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    clc 
    sub nos_low, tos_low 
    sbc nos_high, tos_high 
    movw tos_low, nos_low
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 ) ; w3 = w1 NAND w2 
;
HEADER "NAND", "NAND", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    and tos_low, nos_low 
    and tos_high, nos_high 
    com nos_low 
    com nos_high 
    POON 

;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 ) ; w3 = w1 AND w2 ) 
;
HEADER "AND", "AND", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    and  tos_low, nos_low 
    and  tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 ) ; w3 = w1 OR w2 ) 
;
HEADER "OR", "OR", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    or   tos_low, nos_low 
    or   tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w3 ) ; w3 = w1 XOR w2 ) 
;
HEADER "XOR", "XOR", F_LEAP | F_CORE
    NOOP 
    pspull nos_low, nos_high 
    eor  tos_low, nos_low 
    eor  tos_high, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 -- w2 ) ; arithmetic inverse 
;   by 2's complement, eg 0x0002 to 0xFFFE 
;
HEADER "INVERT", "INVERT", F_LEAP | F_CORE
    NOOP 
_inv: 
    com tos_low 
    com tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w1 -- w2 ) ; logic inverse 
;   by 1's complement, eg 0x0000 to 0xFFFF
;
HEADER "NEGATE", "NEGATE", F_LEAP | F_CORE
    NOOP 
_neg: 
    neg tos_low 
    neg tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w * 2 ) same as shift left << 1, unsigned 
;
HEADER "2*", "SHL", F_LEAP | F_CORE
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
HEADER "2/", "SHR", F_LEAP | F_CORE
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
;   no more offsets then no more branch
HEADER "BRANCH", "BRANCH", F_LEAP | F_CORE
    NOOP 
_branch: 
    rspull zpm_low, zpm_high 
    pmload nos_low, nos_high 
    rspush nos_low, nos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( u -- ) 
; if tos is not zero, skip next 
; 
HEADER "0BRANCH", "ZBRANCH", F_LEAP | F_CORE
    NOOP 
    movw nos_low, tos_low
    pspull tos_low, tos_high
    or nos_low, nos_high
    breq _branch 
    ; skips
    rspull zpm_low, zpm_high 
    adiw zpm_low, 2 
    rspush zpm_low, zpm_high 
    POON
 
;----------------------------------------------------------------------
;
;  ok LIT ( -- w ), 
;  push a value from flash to data stack 
;  note auto increment in pmload
;
HEADER "LIT", "LIT", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high
    rspull zpm_low, zpm_high
    pmload tos_low, tos_high 
    rspush zpm_low, zpm_high
    POON 
 
;----------------------------------------------------------------------
;
; ok ( w -- w ) 
;  data space pointer align to CELL, atmega is always 
;   eg. 0x05 to 0x06, two steps: 
;   1) round a cell down, 2) add one cell 
;
rounds = -1 * CELL_SIZE

HEADER "ALIGNED", "ALIGNED", F_LEAP | F_CORE
    NOOP 
    andi tos_low, -1 * CELL_SIZE 
    adiw tos_low, CELL_SIZE 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- CELL ) 
; CELL is 2 ; size of a cell 
;
HEADER "CELL", "CELL", F_LEAP | F_CORE
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
HEADER "C!", "CTO", F_LEAP | F_CORE
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
HEADER "C@", "CAT", F_LEAP | F_CORE
    NOOP 
    movw zpm_low, tos_low
    ld tos_low, Z
    clr tos_high
    POON 

;----------------------------------------------------------------------
;
; ok ( -- ) does a real absolute jump to address in TOS
;       how return from ? jmp _link
;
HEADER "JUMP", "JUMP", F_LEAP
    NOOP 
; prepare, as LIT ???
;    rspull zpm_low, zpm_high
;    pmload tos_low, tos_high 
;    rspush zpm_low, zpm_high
; does it    
    movw zpm_low, tos_low
    ijmp 

;----------------------------------------------------------------------
;
; ok ( -- 0 ) 
;
HEADER "0", "ZERO", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    clr tos_low 
    clr tos_high 
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- 1 ) 
;
HEADER "1", "ONE", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    clr tos_high 
    ldi tos_low, 1
    POON 

;----------------------------------------------------------------------
;
; ok ( -- 0 ) 
;
HEADER "2", "TWO", F_LEAP | F_CORE
    NOOP 
    pspush tos_low, tos_high 
    clr tos_high 
    ldi tos_low, 2
    POON 
 
;----------------------------------------------------------------------
 
