;----------------------------------------------------------------------
; zzzz
;
HEADER "U*", "mul16u"
    NOOP
;***************************************************************************
;* from avr200.asm
;*
;* "mpy16u" - 16x16 Bit Unsigned Multiplication
;*
;* This subroutine multiplies the two 16-bit register variables 
;* mp16uH:mp16uL and mc16uH:mc16uL.
;* The result is placed in m16u3:m16u2:m16u1:m16u0.
;*  
;***** Subroutine Register Variables

.def	mc16uL	=r16		;multiplicand low byte
.def	mc16uH	=r17		;multiplicand high byte
.def	mp16uL	=r18		;multiplier low byte
.def	mp16uH	=r19		;multiplier high byte
.def	m16u0	=r18		;result byte 0 (LSB)
.def	m16u1	=r19		;result byte 1
.def	m16u2	=r20		;result byte 2
.def	m16u3	=r21		;result byte 3 (MSB)
.def	mcnt16u	=r22		;loop counter

;***** Code

mpy16u:	
	clr	m16u3		;clear 2 highest bytes of result
	clr	m16u2
	ldi	mcnt16u,16	;init loop counter
	lsr	mp16uH
	ror	mp16uL
m16u_1:	
	brcc noad8			;if bit 0 of multiplier set
	add	m16u2,mc16uL	;add multiplicand Low to byte 2 of res
	adc	m16u3,mc16uH	;add multiplicand high to byte 3 of res
noad8:	
	ror	m16u3		;shift right result byte 3
	ror	m16u2		;rotate right result byte 2
	ror	m16u1		;rotate result byte 1 and multiplier High
	ror	m16u0		;rotate result byte 0 and multiplier Low
	dec	mcnt16u		;decrement loop counter
	brne	m16u_1	;if not done, loop more
	ret

;----------------------------------------------------------------------
; zzzz
;
HEADER "U/", "div16u"
    NOOP
;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:19
;* Number of cycles	:235/251 (Min/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;*			    dcnt16u)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	drem16uL=r14
.def	drem16uH=r15
.def	dres16uL=r16
.def	dres16uH=r17
.def	dd16uL	=r16
.def	dd16uH	=r17
.def	dv16uL	=r18
.def	dv16uH	=r19
.def	dcnt16u	=r20

;***** Code

div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry
	ldi	dcnt16u,17	;init loop counter
d16u_1:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	dec	dcnt16u		;decrement counter
	brne	d16u_2		;if done
	ret			;    return
d16u_2:	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_1		;else
d16u_3:	sec			;    set carry to be shifted into result
	rjmp	d16u_1
	
	

;----------------------------------------------------------------------
; ok ( mul mut -- d )
; 16*8 multiplication, 24 bit result, two words result
; multipicand nd_high:nos_low by multiplier wrk_low, 
; result low word quotient in tos_high:tos_low, remainder in wrk_low
;
HEADER "(base8mul16)", "basemul8"
    NOOP
    ; pull multiplicand
    pspull nos_low, nos_high
    ; pull multiplier
    pspull wrk_low, wrk_high
    clr wrk_high
;
; Multiply
;
    ; Multiply LSB
    mul nos_low, wrk_low 
    ; copy result to result register
    mov tos_low, R0 
    mov tos_high, R1
    ; Multiply MSB
    mul nos_high, wrk_low 
    ; copy MSB result to result byte 3
    mov wrk_high, R1 
    ; add LSB result to result byte 2
    add tos_high, R0 
    brcc 10f ; if not carry, jump
    inc wrk_high
10:
    pspush tos_low, tos_high    
    mov tos_low, wrk_high
    clr tos_high
    POON

;----------------------------------------------------------------------
;
; 16/8 division, 16 bit result, 8 bit remainder, two words result
; dividend nos_high:tos_low by divisor tos_low, 
; quotient in tos_high:tos_low, remainder in wrk_low
;
HEADER "(base8div16)", "basediv8"
    NOOP
    ; pull dividend
    pspull nos_low, nos_high
    ; pull divisor
    pspull tos_low, tos_high
10:
    ; clear remainder
    clr wrk_low               
    ; 16 bits rounds
    ldi wrk_high, 0x10         
20:  
    ; next dividend bit to wrk_low
    lsl tos_low
    rol tos_high
    rol wrk_low             
    ; this should never, ever, happen
    brcs 30f                    
    ; trial subtraction
    cp wrk_low, nos_low    
    ; not big enough
    brcs 40f                    
30:
    ; ok, subtract it
    sub wrk_low, nos_low      
    ; add this power of 2 to quotient
    inc tos_low               
40:  
    ; count bit
    dec wrk_high      
    ; do until done
    brne 20b           
     
    ; push quotient
    pspush tos_low, tos_high
    ; push remainder
    movw tos_low, wrk_low
    POON

