

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
; Replace with your application code
start:
.cseg
.org 0x0040

	tos_low = r0
	tos_high = r1

; 16/8 division, 16 bit result, 8 bit remainder
; divide r1:r0 by r24, quotient in r1:r0, remainder in r2
div168:
        clr     r2               ; clear remainder
        ldi     r25,0x10         ; 16 bits
_d161:  lsl     r0
        rol     r1
        rol     r2               ; next dividend bit to r2
        brcs    _d162            ; this should never, ever, happen
        cp      r2,r24           ; trial subtraction
        brcs    _d163            ; not big enough
_d162:  sub     r2,r24           ; ok, subtract it
        inc     r0               ; add this power of 2 to quotient
_d163:  dec     r25              ; count bit
        brne    _d161            ; do until done
		 
end1:
		rjmp end1

;;------------------------------------------------------------
;; AVR 32 / 16 -> 16 bit division by the non-performing method
;; 
;; input:    r3:r2:r1:r0 dividend --> rem:quot
;;           r5:r4       divisor
;; output:   r1:r0       quotient
;; destroys: r0, r1, r2, r3, r6
;;------------------------------------------------------------

    ldi  r6, 16 ; bits = 16
0:
    lsl  r0     ; shift
    rol  r1     ;  rem:quot 
    rol  r2     ;   left 
    rol  r3     ;    by 1
    brcs 1f     ; if carry out, rem > divisor
    cp   r2, r4 ; is rem less
    cpc  r3, r5 ;  than divisor ?
    brcs 2f     ; yes, when carry out
1:  
    sub  r2, r4 ; compute
    sbc  r3, r5 ;  rem -= divisor
    ori  r0, 1  ; record quotient bit as 1
2:
    dec  r6     ; bits--
    brne 0b     ; until bits == 0


        ret                      ; remainder in r2

;----------------------------------------------------------------------
;	https://www.avrfreaks.net/forum/dis-asm-dirty-math-tricks-adventures-division-ten?page=all
;   8bit / 10 ~~~
;	DIV10: MULI A, 26 ; response in R1
;-----------------------------------;
; RETRO (SYNTHETIC) DIVISION BY 10  ;
; ANSWER IN R1, R0=REM, A:PRESERVED ;
;-----------------------------------;
DIV10:  PUSH B
        LDI  B,26   ;MUL BY 26
        MUL  A,B    ;R1=A/10
        PUSH R1     ;BRUTE-FORCE CALC OF REMAINDER      
        LDI  B,10   ;CALC REM
        MUL  R1,B   ;R0=10xR1(QUOT)
        POP  R1     ;RESTORE QUOT
        SUB  R0,A   ;SUBTRACT REMx10
NODJST: NEG  R0     ;MAKE POSITIVE
         BRPL NONEG ;STILL NEG?
        ADD  R0,B   ;OOPS MAKE 
        DEC  R1     ;ADJUSTMENTS
NONEG:   RET

;----------------------------------------
; 8-bit division by 10 routine.
;
; the input number must be in register "input"
; value/10 is in register "result"
; register temp1 and R1:R0 are clobbered
div10:
	ldi temp1, 205
	mul temp1, input
	lsr R1
	lsr R1
	lsr R1
	mov result, R1
	ret
;----------------------------------------
; 8-bit division by 10 routine.
;
; Input: R0 = dividend.
; Output: R1 = result = dividend/10.
;
; Registers R0 and R16 are clobbered.
; 5 words/10 clocks including RET.
; 
div10:
	ldi	r16,205
	mul	r0,r16
	ldi	r16,32
	mul	r1,r16
	ret 
;----------------------------------------

;******************************************************************************;
* DESCRIPTION;* Signed multiply of two 16-bit numbers with 32-bit result.
;* USAGE;* r19:r18:r17:r16 = r23:r22 * r21:r20
;******************************************************************************
muls16x16_32: 
	clr r2 
	muls r23, r21 ; (signed)ah * (signed)bh 
	movw r18, r0 
	mul r22, r20 ; al * bl 
	movw r16, r0 
	mulsu r23, r20 ; (signed)ah * bl 
	sbc r19, r2 
	add r17, r0 
	adc r18, r1 
	adc r19, r2 
	mulsu r21, r22 ; (signed)bh * al 
	sbc r19, r2 
	add r17, r0 
	adc r18, r1 
	adc r19, r2 
	ret
*/
