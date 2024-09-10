

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

/*
;----------------------------------------------------------------------
;*************************************************************************
;*     *
;*      Convert unsigned 16 bit to 5 digit ASCII
;*     *
;*      Author: Peter Dannegger
;*     *
;*************************************************************************
; https://www.avrfreaks.net/forum/smallest-and-fastest-binary-bcd-conversion?page=all
;
;
;input: R17, R16 = 16 bit value 0 ... 65535
;output: R20, R19, R18, R17, R16 = 5 digits (ASCII)
;cycle: 20 ... 170
;
HEADER "utoa", "utoa" 
    NOOP
    ldi zpm_low, lo8(PIC)
    ldi zpm_high, hi8(PIC)
    movw nds_low, zpm_low
    pspull wrk_low, wrk_high
itoa:

    ldi tos_low, -1 + '0'
1:  inc tos_low
    subi wrk_low, lo8(10000)    
    sbci wrk_high, hi8(10000)
    brcc 1b
    st    Z+, wrk_low

    ldi tos_low, 10 + '0'
2:  dec tos_low
    subi wrk_low, lo8(-1000)  
    sbci wrk_high, hi8(-1000)
    brcs 2b
    st Z+, wrk_low

    ldi tos_low, -1 + '0'
3:  inc tos_low
    subi wrk_low, lo8(100)   
    sbci wrk_high, hi8(100)
    brcc 3b
    st Z+, wrk_low

    ldi wrk_high, 10 + '0'
4:  dec wrk_high
    subi wrk_low, -10     
    brcs 4b

    subi wrk_low, -'0'
    st Z+, wrk_low

    pspush nds_low, nds_high
    POON

;----------------------------------------------------------------------
; Converts unsigned integer value ASCII 
;
;    https://www.avrfreaks.net/forum/16bit-binary-ascii
;
dectab:    .dw    10000,1000,100,10,1
HEADER "itoa", "itoa"
    NOOP
    pspull tos_low, tos_high
    pspull nds_low, nds_high
 
itoa_short:
    ldi    zpm_low, low(dectab)
    ldi    zpm_high, high(dectab)
itoa_lext:
    ldi    wrk_low, '0' - 1
    lpm    r2,z+
    lpm    r3,z+
itoa_lint:
    inc    r18
    sub    r16,r2
    sbc    r17,r3
    brsh    itoa_lint
    add    r16,r2
    adc    r17,r3
    st    x+,r18
    cpi    zl,low(dectab*2)+1
    brne    itoa_lext
    ret

;-------------------------------------------------------------

;----------------------------------------------------------------------
; Div8 divides a 16-bit-number by a 8-bit-number
; Test: 16-bit-number: 0xAAAA, 8-bit-number: 0x55
;
.NOLIST
.INCLUDE "8515def.inc"
.LIST
;
; Registers
;
.DEF rd1l = R0 ; LSB 16-bit-number to be divided
.DEF rd1h = R1 ; MSB 16-bit-number to be divided
.DEF rd1u = R2 ; interim register
.DEF rd2 = R3 ; 8-bit-number to divide with
.DEF rel = R4 ; LSB result
.DEF reh = R5 ; MSB result
.DEF rmp = R16; multipurpose register for loading
;
.CSEG
.ORG 0
;
    rjmp start
;
start:
;
; Load the test numbers to the appropriate registers
;
    ldi rmp,0xAA ; 0xAAAA to be divided
    mov rd1h,rmp
    mov rd1l,rmp
    ldi rmp,0x55 ; 0x55 to be divided with
    mov rd2,rmp
;
; Divide rd1h:rd1l by rd2
;
div8:
    clr rd1u ; clear interim register
    clr reh ; clear result (the result registers
    clr rel ; are also used to count to 16 for the
    inc rel ; division steps, is set to 1 at start)
;
; Here the division loop starts
;
div8a:
    clc ; clear carry-bit
    rol rd1l ; rotate the next-upper bit of the number
    rol rd1h ; to the interim register (multiply by 2)
    rol rd1u
    brcs div8b ; a one has rolled left, so subtract
    cp rd1u,rd2 ; Division result 1 or 0?
    brcs div8c ; jump over subtraction, if smaller
div8b:
    sub rd1u,rd2; subtract number to divide with
    sec ; set carry-bit, result is a 1
    rjmp div8d ; jump to shift of the result bit
div8c:
    clc ; clear carry-bit, resulting bit is a 0
div8d:
    rol rel ; rotate carry-bit into result registers
    rol reh
    brcc div8a ; as long as zero rotate out of the result
     ; registers: go on with the division loop
; End of the division reached
stop:
    rjmp stop ; endless loop
/*

from https://www.daniweb.com/programming/threads/510730/lc3-converts-hex-or-decimal-to-16-bit-binary

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseDecimal
    LD      R5, NegZERO    
    LD      R6, NegNINE    
    AND     R3, R3, #0      ; Set R3 to 0
DecimalLoop
    LDR     R4, R2, #0      ; Put next digit into R4
    BRz     DoneParsingDecimal  ; If it is the null terminator, done parsing

    ;; Confirm that it is a valid digit
    ADD     R0, R4, R5      ; Compare to "0"
    BRn     ParseError      ; If less than "0", not a digit
    ADD     R0, R4, R6      ; Compare to "9"
    BRp     ParseError      ; If greater than "9", not a digit

    ;; Multiply R3 by 10
    ADD     R7, R3, R3      ; R7 = 2*R3
    ADD     R3, R7, R7      ; R3 = 4*R3
    ADD     R3, R3, R3      ; R3 = 8*R3
    ADD     R3, R3, R7      ; R3 = 8*R3 + 2*R3 = 10*R3

    ;; Add new digit to R3
    ADD     R4, R4, R5      ; Make binary
    ADD     R3, R3, R4      ; Add new digit
    ADD     R2, R2, #1      ; Increment memory pointer
    BRnzp   DecimalLoop

DoneParsingDecimal
    ;; Check if we need to negate the result for the minus sign
    ADD     R1, R1, #0       ; If R1 is not -1, skip negation of R3
    BRzp    NotNegativeDecimal 
    NOT     R3, R3
    ADD     R3, R3, #1      ; Negate R3
NotNegativeDecimal
    BRnzp   PrintResult

NegZero .FILL   -48     ; Negative ASCII "0"
NegNine .FILL   -57     ; Negative ASCII "9"


*/
