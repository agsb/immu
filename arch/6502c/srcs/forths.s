

;----------------------------------------------------------------------
; Copyright (c) 2023, Alvaro Gomes Sobral Barcellos
; All rights reserved.
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
; 
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
; 
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

; ---------------------------------------------------------------------
; Forth like functions
; to keep code safe by not using "fall throught".
; uses A, Y, X caller must saves.
; needs 2 levels of hardware stack
; uses 4 bytes in page zero as temporary, TOS and NOS
; uses 6 bytes in memory for internal use
; ---------------------------------------------------------------------

; ---------------------------------------------------------------------
;   data stack stuff

keep_: ; to push
    ; ldx dat_indx
    dex
    dex
    stx dat_indx
    rts

lose_: ; to pull
    ; ldx dat_indx
    inx
    inx
    stx dat_indx
    rts

spush:
push_:
    ldx dat_indx
    lda tos + 0
    sta dat_zero - 2, x
    lda tos + 1
    sta dat_zero - 1, x
    jmp keep_

spull:
pull_:
    ldx dat_indx
    lda dat_zero + 0, x
    sta tos + 0
    lda dat_zero + 1, x
    sta tos + 1
    jmp lose_

.ifdef FULL_STACK_CODES
push2_:
    ldx dat_indx
    lda nos + 0
    sta dat_zero - 4, x
    lda nos + 1
    sta dat_zero - 3, x
    lda tos + 0
    sta dat_zero - 2, x
    lda tos + 1
    sta dat_zero - 1, x
    jsr keep_
    jmp keep_
.endif

take2:
pull2_:
    ldx dat_indx
    lda dat_zero + 0, x
    sta tos + 0
    lda dat_zero + 1, x
    sta tos + 1
    lda dat_zero + 2, x
    sta nos + 0
    lda dat_zero + 3, x
    sta nos + 1
    jsr lose_
    jmp lose_

drop_:
    ldx dat_indx
    jsr lose_
    ; rts
    jmp link_

dup_:
    ldx dat_indx
    lda dat_zero + 0, x
    sta dat_zero - 2
    lda dat_zero + 1, x
    sta dat_zero - 1
    jsr keep_
    ; rts
    jmp link_

over_:
    ldx dat_indx
    lda dat_zero + 2, x
    sta dat_zero - 2
    lda dat_zero + 3, x
    sta dat_zero - 1
    jsr keep_
    ; rts
    jmp link_

swap_:
    ldx dat_indx
    lda dat_zero + 0, x
    sta dat_zero - 2
    lda dat_zero + 1, x
    sta dat_zero - 1
    lda dat_zero + 2, x
    sta dat_zero + 0
    lda dat_zero + 3, x
    sta dat_zero + 1
    lda dat_zero - 2, x
    sta dat_zero + 2
    lda dat_zero - 1, x
    sta dat_zero + 3
    ; rts
    jmp link_

rot_:
    ldx dat_indx
    lda dat_zero + 4, x
    sta dat_zero - 2
    lda dat_zero + 5, x
    sta dat_zero - 1
    lda dat_zero + 2, x
    sta dat_zero + 4
    lda dat_zero + 3, x
    sta dat_zero + 5
    lda dat_zero + 0, x
    sta dat_zero + 2
    lda dat_zero + 1, x
    sta dat_zero + 3
    lda dat_zero - 2, x
    sta dat_zero + 0
    lda dat_zero - 1, x
    sta dat_zero + 1
    ; rts
    jmp link_

and_:
    ldx dat_indx
    lda dat_zero + 0, x
    and dat_zero + 2, x
    sta dat_zero + 2, x
    lda dat_zero + 1, x
    and dat_zero + 3, x
    sta dat_zero + 3, x
    jmp drop_

or_:
    ldx dat_indx
    lda dat_zero + 0, x
    ora dat_zero + 2, x
    sta dat_zero + 2, x
    lda dat_zero + 1, x
    ora dat_zero + 3, x
    sta dat_zero + 3, x
    jmp drop_

xor_:
    ldx dat_indx
    lda dat_zero + 0, x
    eor dat_zero + 2, x
    sta dat_zero + 2, x
    lda dat_zero + 1, x
    eor dat_zero + 3, x
    sta dat_zero + 3, x
    jmp drop_

cpt_:
    ldx dat_indx
    sec
    tya
    sbc dat_zero + 0, x
    sta dat_zero + 0, x
    sec
    tya
    sbc dat_zero + 1, x
    sta dat_zero + 1, x
    ; rts
    jmp link_

neg_:
    lda #$00
    tay
    jmp cpt_

inv_:
    lda #$FF
    tay
    jmp cpt_

sub_:
    ldx dat_indx
    sec
    lda dat_zero + 2, x
    sbc dat_zero + 0, x
    sta dat_zero + 2, x
    lda dat_zero + 3, x
    sbc dat_zero + 1, x
    sta dat_zero + 3, x
    jmp drop_

add_:
    ldx dat_indx
    clc
    lda dat_zero + 2, x
    adc dat_zero + 0, x
    sta dat_zero + 2, x
    lda dat_zero + 3, x
    adc dat_zero + 1, x
    sta dat_zero + 3, x
    jmp drop_

cmp_:
    ldx dat_indx
    sec
    lda dat_zero + 2, x
    sbc dat_zero + 0, x
    lda dat_zero + 3, x
    sbc dat_zero + 1, x
    rts

eq_:
    jsr cmp_
    beq true2_
    bne false2_

lt_:
    jsr cmp_
    bmi true2_
    bpl false2_

gt_:
    jsr cmp_
    bmi false2_
    beq false2_
    bpl true2_

same2_:
    ldx dat_indx
    sta dat_zero + 2, x
    sta dat_zero + 3, x
    jmp drop_

false2_:
    lda #(FALSE)
    beq same2_

true2_:
    lda #(TRUE)
    bne same2_

shl_:
    ldx dat_indx
    asl dat_zero + 0, x
    rol dat_zero + 1, x
    ; rts
    jmp link_

shr_:
    ldx dat_indx
    lsr dat_zero + 0, x
    ror dat_zero + 1, x
    ; rts
    jmp link_

cto_:
    jsr pull2_
    ldy #0
    lda nos + 0
    sta (tos), y
    rts

to_:
    jsr cto_
    iny
    lda nos + 1
    sta (tos), y
    rts

cStore_:
    jsr cto_
    ; rts
    jmp link_

store_:
    jsr to_
    ; rts
    jmp link_

cat_:
    ldx dat_indx
    lda dat_zero + 0, x
    sta tos + 0
    lda dat_zero + 1, x
    sta tos + 1
    ldy #0
    lda (tos), y
    sta dat_zero + 0, x
    rts

at_:
    jsr cat_
    iny
    lda (tos), y
    sta dat_zero + 1, x
    rts

cFetch_:
    jsr cat_
    ; rts
    jmp link_

fetch_:
    jsr at_
    ; rts
    jmp link_

incr_:
    ldx dat_indx
    inc dat_zero + 0, x
    bne @ends
    inc dat_zero + 1, x
@ends:
    ; rts
    jmp link_

decr_:
    ldx dat_indx
    lda dat_zero + 0, x
    bne @ends
    dec dat_zero + 1, x
@ends:
    dec dat_zero + 0, x
    ; rts
    jmp link_

jump_:
    ldx dat_indx
    lda dat_zero + 1,x
    pha
    lda dat_zero + 0,x
    pha
    php
    rti

addto_:
    jsr pull2_
    ldy #NUL
    clc
    lda (tos), y
    adc nos + 0
    sta (tos), y
    iny
    lda (tos), y
    adc nos + 1
    sta (tos), y
    ; rts
	jmp link_

subto_:
    jsr pull2_
    ldy #NUL
    sec
    lda (tos), y
    sbc nos + 0
    sta (tos), y
    iny
    lda (tos), y
    sbc nos + 1
    sta (tos), y
    ; rts
	jmp link_

;----------------------------------------------------------------------
;   return stack stuff

rpush_:
    ldx dat_indx
    lda tos + 0
    sta ret_zero - 2, x
    lda tos + 1
    sta ret_zero - 1, x
    dex
    dex
    stx dat_indx
    rts

rpull_:
    ldx dat_indx
    lda ret_zero + 0, x
    sta tos + 0
    lda ret_zero + 1, x
    sta tos + 1
    inx
    inx
    stx dat_indx
    rts

rshow_:
    ldx dat_indx
    lda ret_zero + 0, x
    sta tos + 0
    lda ret_zero + 1, x
    sta tos + 1
    jsr push_
    ; rts
    jmp link_

r2s_:
    jsr rpull_
    jsr push_
    ; rts
    jmp link_

s2r_:
    jsr pull_
    jsr rpush_
    ; rts
    jmp link_

;----------------------------------------------------------------------
; prepare for mult or divd
opin:
    ldx dat_indx
    ; pseudo tos
    lda dat_zero + 0, x
    sta wrk + 0
    lda dat_zero + 1, x
    sta wrk + 1
    ; pseudo nos
    lda dat_zero + 2, x
    sta tmp + 0
    lda dat_zero + 3, x
    sta tmp + 1
    ; clear results
    lda #NUL
    sta tos + 0
    sta tos + 1
    sta nos + 0
    sta nos + 1
    ; countdown
    ldy #16
    rts

;----------------------------------------------------------------------
; resume from mult or divd
opout:
    ; copy results
    ldx dat_indx
    lda nos + 0
    sta dat_zero + 0, x
    lda nos + 1
    sta dat_zero + 1, x
    lda tos + 0
    sta dat_zero + 2, x
    lda tos + 1
    sta dat_zero + 3, x
    ; rts
    jmp link_

;----------------------------------------------------------------------
; Divide the top 2 cell of the stack
; http://codebase64.org/doku.php?id=base:16bit_division_16-bit_result
; dividend divisor -- result remainder
; ( tmp wrk -- nos tos )
div_:
    jsr opin
@loop:
    asl tmp + 0
    rol tmp + 1
    rol tos + 0
    rol tos + 1
    sec
    lda tos + 0
    sbc wrk + 0
    tax
    lda tos + 1
    sbc wrk + 1
    bcc @skip
    sta tos + 1
    stx tos + 0
    inc tmp + 0
@skip:
    ; countdown
    dey
    bne @loop
    ; results
    lda tmp + 0
    sta nos + 0
    lda tmp + 1
    sta nos + 1
    ; ends
    jmp opout

;----------------------------------------------------------------------
; 16-bit multiply 16x16, 32 result
; http://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product
; ( multiplicand multiplier -- resultMSW resultLSW )
; ( tmp wrk -- nos tos )
mul_:
    jsr opin
@shift_r:
    ; divide by 2
    lsr wrk + 1
    ror wrk + 0
    bcc @rotate_r
    ; add multiplicand to upper half product
    tax
    clc
    lda tmp + 0
    adc tos + 0
    sta tos + 0
    txa
    adc tmp + 1
@rotate_r:
    ; rotate partial product upper to low
    ror
    ror tos + 1
    ror nos + 1
    ror nos + 0
    ; countdown
    dey
    bne @shift_r
    sta tos + 0
    ; ends
    jmp opout

; set overflow bit
slv:
    bit @ends
@ends:
    rts

