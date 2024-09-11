 
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

