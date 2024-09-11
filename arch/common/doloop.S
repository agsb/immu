;----------------------------------------------------------------------
;
; DO and LOOP runs from 0x8000 till 0x7FFF, -32768 to 32767
; counting from 0 to 65535, as Forth-83
; ZZZZ
;


;----------------------------------------------------------------------
;
; ok LEAVES (Forth-83)
;
HEADER "LEAVES", "LEAVES", 
    .word LIT, LEAVES, ENDS
 
LEAVES:    .word 0     ; hold for leaves

;----------------------------------------------------------------------
;
; ok DO (Forth-83)
;
HEADER "DO", "DO", F_IMMEDIATE,
    .word HERE, TOR, DOCON, 0x8000, PLUS, DUP, TOR, MINUS, TOR, ENDS 
 
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
    .word OVER, OVER, MINUS, COMPILE, ZBRANCH, HERE, DO, ENDS 
 
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
