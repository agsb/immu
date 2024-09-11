;**********************************************************************
;
;   picture number routines adapted
;   from eForth, 1003_InsideF83, Dr. Ting
;   
;----------------------------------------------------------------------
;
; those are intented to use together, with no word creation inside.
;
;   <# # #S DIGIT HOLD SIGN #>
;
;----------------------------------------------------------------------
;   is DIGIT ( c -- true | false )
;   eg. 0-9~A-F in base 16, true
;   ok for bases 2 to 36
;   no sign or period inside
;
HEADER "DIGIT", "DIGIT",
    .word LIT, '0', MINUS
    .word DUP, ZERO, LTHAN, ZBRANCH, 5f
    .word DUP, LIT, 9, LTHAN, ZBRANCH, 6f
    .word DUP, LIT, 17, LTHAN, ZBRANCH, 5f
    .word LIT, 7, MINUS
    .word DUP, BASE, MINUS, LTHAN, ZBRANCH, 6f 
5:  .word DROP, FFALSE, ENDS
6:  .word DROP, FTRUE, ENDS

;----------------------------------------------------------------------
;   is <#
;
HEADER "<#", "LTSNUM",
    .word PAD, LIT, HLD, TO, ENDS

;----------------------------------------------------------------------
;   is HOLD
;   : HOLD HLD @ CHAR- DUP HLD ! C! ; 
;
HEADER "HOLD", "HOLD",
    .word HLD, AT, CHARMINUS, DUP, HLD, TO, CTO, ENDS

;----------------------------------------------------------------------
;   is #
;   : # 0 BASE @ UM/MOD >R BASE @ UM/MOD SWAP DIGIT HOLD R> ; 
;
HEADER "#", "SNUM",
    .word ZERO, BASE, AT, UMDIVMOD, TOR, BASE, AT, UMDIVMOD
    .word SWAP, DIGIT, HOLD, RTO, ENDS

;----------------------------------------------------------------------
;   is #S
;   : #S BEGIN # 2DUP OR 0= UNTIL ; 
;   do { ... } while
;
HEADER "#S", "SNUMS",
    .word SNUM, TWODUP, OR, ZEQU, ZBRANCH, SNUMS, ENDS

;----------------------------------------------------------------------
;   is SIGN
;   : SIGN 0< IF [CHAR] - HOLD THEN ; 
;
HEADER "SIGN", "SIGN",
    .word ZEROLT, ZBRANCH, 2f
    .word [CHAR], MINUS, HOLD
2:  .word ENDS

;----------------------------------------------------------------------
;   is #>
;
HEADER "#>", "SNUMGT",
    .word TWODROP, HLD, AT, PAD, OVER, MINUS, ENDS

;----------------------------------------------------------------------


;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "(U.)", "UDOTP",
    .word ZERO, LTSNUM, SNUMS, SNUMGT, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "U.", "UDOT",
    .word UDOTP, TYPE, SPACE, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "U.R", "UDOTR",
    .word TOR, UDOTP, RTO, OVER, MINUS, SPACES, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "(.)", "DOTP",
    .word DUP, ABS, 0, LTSNUM, SNUMS, ROTU, SIGN, SNUMGT, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER ".", "DOT",
    .word DOTP, TYPE, SPACE, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "?", "QUESTION",
    .word AT, DOT, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER ".R", "DOTR",
    .word TOR, DOTP, RTO, OVER, MINUS, SPACES, TYPE, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "(UD.)", "UDDOTP",
    .word LTSNUM, SNUMS, SNUMGT, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "UD.", "UDDOT",
    .word UDDOTP, TYPE, SPACE, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "UD.R", "UDDOTR",
    .word TOR, UDDOTP, RTO, OVER, MINUS, SPACES, TYPE, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "(D.)", "DDOTP",
    .word TUCK, DABS, LTSNUM, SNUMS, ROTU, SIGN, SNUMGT, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "D.", "DDOT",
    .word DDOTP, TYPE, SPACE, ENDS

;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "D.R", "DDOTR",
    .word TOR, DDOTP, ROTU, OVER, SPACES, TYPE, ENDS

;**********************************************************************

