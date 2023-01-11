;------------------------------------------------------------------------------
.END
;
;==============================================================================   
; some code to study
;------------------------------------------------------------------------------
;
;---------------------------------------------------------------------
; zzzz not finished
;
; next: 
;   ldy irqnot
;   beq runISR
;   ...
;   bcs inc_hi
;   jmp wrk - 1
;
;inc_hi:
;   inc nos + 1
;   jmp wrk - 1
;
HEADER "IRQOK", "IRQOK", F_LEAP, LEAF
    cli
    ; continue
    jmp unnest

HEADER "NOIRQ", "NOIRQ", F_LEAP, LEAF
    sei
    ; continue
    jmp unnest

HEADER "SYSRTI", "SYSRTI", F_LEAP, LEAF
    sei
    lda irqnot
    beq noi
    cli
noi:
    ; continue
    jmp unnest

HEADER "IRQOK?", "IRQOKQ", F_LEAP, LEAF
    php
    pla
    and #4
    beq irqf
    jmp FFALSE
irqf: 
    jmp FTRUE

runISR:
    inc irqnot
    jmp (irqvec)

irqroute:
    jmp (irqvec)

setirq:
    sta a_save
    ; clear byte irq flag
    lda #0
    sta irqnot
    ; set bit 4 flag
    pla
    ora #4
    pha
    lda a_save
    rti

;------------------------------------------------------------------------------
;   check address lines a14 to a0
;   http://6502.org/source/general/address_test.html
;
;   to check ram, use $55 $AA in every address
;
;------------------------------------------------------------------------------

;==============================================================================
;------------------------------------------------------------------------------
;https://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product

;16-bit multiply with 32-bit result 
;took from 6502.org
 
multiplier	= $f7 
multiplicand	= $f9 
product		= $fb 
 
mult16: 		
        lda	#$00
		sta	product+2	; clear upper bits of product
		sta	product+3 
		ldx	#$10		; set binary count to 16 
shift_r:
        lsr	multiplier+1	; divide multiplier by 2 
		ror	multiplier
		bcc	rotate_r 
		lda	product+2	; get upper half of product and add multiplicand
		clc
		adc	multiplicand
		sta	product+2
		lda	product+3 
		adc	multiplicand+1
rotate_r:
        ror			; rotate partial product 
		sta	product+3 
		ror	product+2
		ror	product+1 
		ror	product 
		dex
		bne	shift_r 
		rts


;---------------------------------------------------------------------
;16-bit division with 32-bit result 
;took from 6502.org

divisor = $58     ;$59 used for hi-byte
dividend = $fb	  ;$fc used for hi-byte
remainder = $fd	  ;$fe used for hi-byte
result = dividend ;save memory by reusing divident to store the result

divide:	
	lda #0	        ;preset remainder to 0
	sta remainder
	sta remainder+1
	ldx #16	        ;repeat for each bit: ...

divloop:
	asl dividend	;dividend lb & hb*2, msb -> Carry
	rol dividend+1	
	rol remainder	;remainder lb & hb * 2 + msb from carry
	rol remainder+1
	lda remainder
	sec
	sbc divisor	;substract divisor to see if it fits in
	tay	        ;lb result -> Y, for we may need it later
	lda remainder+1
	sbc divisor+1
	bcc skip	;if carry=0 then divisor didn't fit in yet

	sta remainder+1	;else save substraction result as new remainder,
	sty remainder	
	inc result	;and INCrement result cause divisor fit in 1 times

skip:
	dex
	bne divloop	
	rts

;==============================================================================

; @Lee Davison
;
;   1.  clear carry, and set N Z
;
;   rol a
;   eor #$1
;   ror a
;
;   2.  check 0 < n < m < $FF
; 
;   sec
;   sbc #n            ; 
;   sbc #m - n + 1    ;
;   bcc   n < A < m 
;
;   3. nibble to ASCII
;
;   and #$0F
;   cmp #$0A
;   bcc @no
;   adc #6
;@no:
;   adc #'0'
;

