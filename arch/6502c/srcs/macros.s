;---------------------------------------------------------------------
; /*
;  *  DISCLAIMER"
;  *
;  *  Copyright © 2020, Alvaro Gomes Sobral Barcellos,
;  *
;  *  Permission is hereby granted, free of charge, to any person obtaining
;  *  a copy of this software and associated documentation files (the
;  *  "Software"), to deal in the Software without restriction, including
;  *  without limitation the rights to use, copy, modify, merge, publish,
;  *  distribute, sublicense, and/or sell copies of the Software, and to
;  *  permit per0ons to whom the Software is furnished to do so, subject to
;  *  the following conditions"
;  *
;  *  The above copyright notice and this permission notice shall be
;  *  included in all copies or substantial portions of the Software.
;  *
;  *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;  *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;  *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE and
;  *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;  *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;  *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;  *
;  */
;
;   LICENSE: http://creativecommons.org/licenses/by-nc-sa/4.0/
;
;---------------------------------------------------------------------
;
;   this is for MOS6502A with CC65 suit
;
;   04/01/2023   please read the Notes.md
;
;---------------------------------------------------------------------
;
;   enable some ca65  
;
; enable listing
.list on

; identifiers
.case +

; enable 6502 mode
.p02

; debug 
.debuginfo +

; enable C comments
.feature c_comments

;---------------------------------------------------------------------
; 
;   defines

.define VERSION "0.01.02"

;---------------------------------------------------------------------
; 
;   ancient borrow
    NULL    = $0000

;   6502 hardware
    ZPAGE   = $000
    STACK   = $100

;   logical flags, forth 83
    FALSE   = $0000
    TRUE    = $FFFF

;   buffer sizes
    TIB_SIZE  = 80
    PAD_SIZE  = 72

;   cell is 16 bits, 2 bytes, common
    CELL_SIZE = 2

;   maximum word size, not standart
    WORD_SIZE = 15

;   default base
    BASE_DEFAULT = 16

;---------------------------------------------------------------------
;   forth dictionary:
;
;   | link | size + flags | name + pad | code ~~~ ends |
;
;   link, .word, link to previous forth 
;   size+flags, .byte, size of name (1 - 15)
;   name+pad, .bytes, characters of name (+pad)  
;   code, .words, array of references or code
;   ends, .word, jump or reference to unnest
;
;---------------------------------------------------------------------
;
;   forth words flags
; 
    F_RESERVED  = $80   ; old sytle 
    F_IMMEDIATE = $40
    F_COMPILE   = $20
    F_HIDDEN    = $10   ; old SMUDGE

;
    F_TOMASK = $F0
    F_UNMASK = $0F

;   not really flags but nice look at listings
    F_LEAP = $00   ; for primitives
    F_CORE = $00   ; for core words

;---------------------------------------------------------------------
;
;   minimal error codes from forth 2012
;   2's complement
;
    NO_ERROR = 0
    INVALID_MEMORY  = $FFF7     ; -9
    OUT_OF_RANGE    = $FFF5     ; -11
    INVALID_WORD    = $FFF3     ; -13
    TO_READ_ONLY    = $FFEC     ; -20
    NOT_A_NUMBER    = $FFE8     ; -24

;---------------------------------------------------------------------
;   ASCII constants
;
;   Flow Control
;   assumes that all line edit is done at remote!
;   just a static line, receives a line until a CR or CR LF
;   uses BS, for edit last char
;
    ESC_    =   27    ; ascii escape ^[
    XON_    =   17    ; ascii DC1 ^Q
    XOFF_   =   19    ; ascii DC3 ^S

    CR_     =   13    ; ascci carriage return ^M
    LF_     =   10    ; ascii line feed ^J
    BS_     =    8    ; ascii backspace ^H

    BL_     =   32    ; ascii space
    QT_     =   34    ; ascii double quotes \"

;---------------------------------------------------------------------
;   task or process states
    HALT    = 0
    IDLE    = 1
    WAIT    = 2
    BUSY    = 3

;---------------------------------------------------------------------
; interpreter states
    INTERPRET = 0
    COMPILING = 1
    
;=====================================================================
;
;   macros 


;---------------------------------------------------------------------
.macro typestring display, string
    jsr display
    .byte @str1 - @str0
@str0:
    .byte string
@str1:
.endmacro

;---------------------------------------------------------------------
.macro makelabel arg1, arg2
.ident(.concat(arg1, arg2)):
.endmacro

;---------------------------------------------------------------------

hcount .set 0          ; Initialize the counter

H0000 = 0

.macro HEADER name, label, flags, leaf
.ifblank leaf
    .out " No leaf "
.endif
.ifblank flags
    .out " No flags "
.endif
.ifblank label
    .error " No label "
.endif
.ifblank name
    .error " No name "
.endif

;   6502 cpu is byte unit .align 1, $00  
makelabel "is_", label
.ident(.sprintf("H%04X", hcount + 1)) = *
    .word   .ident (.sprintf ("H%04X", hcount))
    hcount .set hcount + 1
    .byte .strlen(name) + ( F_RESERVED | flags ) + 0
    .byte name
    ; .align 1, $20, but no need PAD
;   all primitives (leafs) must start with NULL
.ifnblank leaf 
    .word NULL
.endif 
;   6502 cpu is byte unit .align 1, $00  
makelabel "", label
.endmacro

;=====================================================================
