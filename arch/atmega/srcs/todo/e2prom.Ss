

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

;----------------------------------------------------------------------
;792486AA–AVR–02/2013 ATmega8(L)Note:1.   See “About Code Examples” on page 8
;
; from atmeg8 datasheet
;
#define EEARH   0x1F
#define EEARL   0x1E
#define EEDR    0x1D
#define EECR    0x1C
#define EEWE    1
#define EEMWE   2
#define EERE    0

;----------------------------------------------------------------------
; EEPROM_write: ( u w -- )
; address is one of 0 to 511 ( 128 pages of 4 bytes )
;
HEADER "(weep)", "weep"
    NOOP
    pspull wrk_low, wrk_high
    pspull tos_low, tos_high
    clr _work_
    inc _work_
    inc _work_
EEPROM_write:
; Wait for completion of previous write
1:
    sbic EECR, EEWE
    rjmp 1b
; Set up address in address register
    out EEARH, wrk_high
    out EEARL, wrk_low
; Write data to data register
    out EEDR, tos_low
; disable interrupts
    cli
; Write logical one to EEMWE
    sbi EECR, EEMWE
; Start eeprom write by setting EEWE
    sbi EECR, EEWE
; enable interrupts
    sei
; repeat for high byte
    dec _work_
    brbs 1, 2f
    adiw wrk_low, 1
    cp tos_low, tos_high
    rjmp 1b
2:
    POON

;----------------------------------------------------------------------
; EEPROM_read: ( w -- u )
; address is one of 0 to 511 ( 128 pages of 4 bytes )
;
HEADER "(reep)", "reep"
    NOOP
    pspull wrk_low, wrk_high
    clr _work_
    inc _work_
    inc _work_
EEPROM_read:
; Wait for completion of previous write
1:  
    sbic EECR, EEWE
    rjmp 1b
; Set up address in address register
    out EEARH, wrk_high
    out EEARL, wrk_low
; Start eeprom read by writing EERE
    sbi EECR, EERE
; Read data from data register
    in tos_high, EEDR
; repeat for high byte
    dec _work_
    brbs 1, 2f
    adiw wrk_low, 1
    mov tos_low, tos_high
    rjmp 1b
2:
    pspush tos_low, tos_high
    POON

;----------------------------------------------------------------------
;
; ok 
;	save into and load from eeprom
;
HEADER "(here!e)", "hereto"
	.word HERE, AT, e_here, weep, ENDS

HEADER "(here@e)", "hereat"
	.word e_here, reep, HERE, TO, ENDS

HEADER "(last!e)", "lastto"
	.word LAST, AT, e_last, weep, ENDS

HEADER "(last@e)", "lastat"
	.word e_last, reep, LAST, TO, ENDS

HEADER "(seed!e)", "seedto"
	.word SEED, AT, e_seed, weep, ENDS

HEADER "(seed@e)", "seedat"
	.word e_seed, reep, SEED, TO, ENDS

HEADER "(sram!e)", "sramto"
	.word SRAM, AT, e_sram, weep, ENDS

HEADER "(sram@e)", "sramat"
	.word e_sram, reep, SRAM, TO, ENDS

HEADER "(erom!e)", "eromto"
	.word EROM, AT, e_erom, weep, ENDS

HEADER "(erom@e)", "eromat"
	.word e_erom, reep, EROM, TO, ENDS


