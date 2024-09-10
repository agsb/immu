
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
; atmega8 avr
;
; UPDATE: 10/2022 to include stuff for atmega328 
;---------------------------------------------------------------------- 
;
; version information
;
.equ version, 12 ; 0.00.10

#include "macros.S"
;----------------------------------------------------------------------
;
; for sake stacks grows down, heaps grows up
;
;----------------------------------------------------------------------
.section .eeprom
.org 0x000

e_void:	.word 0 ; always zero
e_live:	.word 0 ; seed for random
e_turn:	.word 0 ; routine after boot
e_rest:	.word 0 ; routine before reset
e_last:	.word 0 ; link to last word in dictionary
e_dp:	.word 0 ; next free flash address for dictionary
e_up:	.word 0 ; next free sram address for variables, backwards
e_ep:	.word 0 ; next free eprom address for values, 

EP0 = .

;----------------------------------------------------------------------
.section data
.org SRAM_START

;----------------------------------------------------------------------
; Terminal input buffer
TIB0:	.space TIB_SIZE, 0x0

;----------------------------------------------------------------------
; Stacks
SPZ:    .space STACK_SIZE, 0x0
SP0 = .
PSZ:    .space STACK_SIZE, 0x0
PS0 = .
RSZ:    .space STACK_SIZE, 0x0
RS0 = .

;----------------------------------------------------------------------
; non volatile, must be saved in eeprom
VOID:	.word 0		; always 0x0000
LIVE:   .word 0     ; count boots

TURN:	.word 0		; routine to run after boot
REST:	.word 0		; routine to run before reset

LAST:	.word 0		; reference to latest word in dictionary
VDP:	.word 0		; next free cell in flash dictionary

VUP:    .word 0     ; next free cell in static ram, backwards
VEP: 	.word 0		; next free cell in eeprom

;----------------------------------------------------------------------
; those are volatile, dont care
VHP:    .word 0     ; next free cell in static ram, forward
SEED:   .word 0     ; random seed

STAT:	.word 0		; state of interpreter, 0 interprete, 1 compile
RADX:	.word 0		; numeric radix for convertion

TOIN:   .word 0     ; offset in TIB
SPAN:   .word 0     ; offset in user buffer

SCRS:   .word 0     ; screen number
BLKS:   .word 0     ; block number

HAND:   .word 0     ; handler for catch and throw
CSPP:   .word 0     ; keep last ps

CURR:   .word 0     ; reference to current vocabulary
CTXT:   .word 0     ; reference to context vocabulary

HLD:    .word 0     ; picture number buffer
HLDS:   .word 0     ; picture number cursor

WARN:   .word 0     ; warning number
ERRN:   .word 0     ; error number

TMP0:   .word 0     ; temporary
TMP1:   .word 0     ; temporary
TMP2:   .word 0     ; temporary
TMP3:   .word 0     ; temporary

;----------------------------------------------------------------------
UH0 = .

US0 = SRAM_END

;.equ is_free_sram,  US0 - UH0

;----------------------------------------------------------------------
;
; code segment, flash
;
; all start text segment is in bios.S
;----------------------------------------------------------------------
.p2align 1, 0x00
#include "bios.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "messages.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "forth-leafs.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "forth-twigs.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "doubles.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "math.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "flush.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "pictures.S"

;----------------------------------------------------------------------
.p2align 1, 0x00
#include "interpreter.S"

;----------------------------------------------------------------------
;
; is ZZZZ, hook for incompleteness 
;
HEADER "UNDEF", "UNDEF",
ZZZZ:
    .word LIT, undefined, LIT, 12, TYPE, CR, ENDS 
 
;----------------------------------------------------------------------
.p2align 1, 0x00
.equ free_flash, .

;********************************************************************** 

;----------------------------------------------------------------------

/*
1 	1st 	fst,    first  
2 	2nd 	snd,    second
3 	3rd 	thd,    third
4 	4th 	fth,    fourth
and so on is th :)
*/


