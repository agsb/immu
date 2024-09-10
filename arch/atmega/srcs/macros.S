
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
;   MUST use gnu cpp 
;   use with .S (upper S) or
;   use with -x assembler-with-cpp
;
;     can't use alias 
;----------------------------------------------------------------------
;
; all defines, equs, macros are defined in this file
;

#define atmega328

;----------------------------------------------------------------------
;
;    about registers 
;
; r1:r0 reserved and used in internal atmega8
;   instructions, as spm, mul, des, etc
;   do not use inside interrupts

#define _reserved_r0_ r0
#define _reserved_r1_ r1

;----------------------------------------------------------------------
;
;  reserved for use inside timer0 interrupt
;
; sreg keep in interrupts
#define _sreg_ r2

; offset for adjust timer0 interrupt counter
#define _offs_ r3

; ticks counter for timer0 at 1 ms, (count 65 sec)
#define ticks_low  r4
#define ticks_high r5

;-----------------------------------------------------------------------
;
; forth model (like pdp-11)
;
; must be 16bits (16 to 31) registers
;
; avr virtual machine as https://www.controllersandpcs.de/Project_sources/Macro_Reference.pdf
;

; Z generic pointer for access sram and flash memory, lpm, spm, index, etc
#define zpm_low r30
#define zpm_high r31

; Y parameter stack pointer for access sram
#define psp_low r28
#define psp_high r29

; X return stack pointer for access sram
#define rsp_low r26
#define rsp_high r27

; top, Top parameter stack, A in avr virtual machine
#define tos_low r24
#define tos_high r25

; nos, Next temporary, B in avr virtual machine
#define nos_low r22
#define nos_high r23

; wrk, Work temporary, C in avr virtual machine 
#define wrk_low r20
#define wrk_high r21

; ipt, instruction pointer, C in avr virtual machine 
#define ipt_low r18
#define ipt_high r19

; extras
#define _zero_ r6
#define _work_ r7

; registers r8 to r17 free

;.altmacro

;----------------------------------------------------------------------
;
;  trick adapted from amforth-6.9
;
.macro STRINGS string
    .byte 8f - 7f
7:  .string "\string"
8:  .balign 2
.endm

;----------------------------------------------------------------------
;
; header of leaf word in dictionary
;    flags must be 0x80, 0x40, 0x20, 0x10
;    size  must be 1 to 15
;
;----------------------------------------------------------------------
;
; set start reverse linked list
;
.set _link_, 0x0
.set _list_, 0x0
.set _last_, 0x0

.macro HEADER name, label, flags=0x0
is_\label:
10:
    .p2align 1, 0x00
7:    
    .word _link_
    .set _link_, 7b
    .byte (9f - 8f) + \flags
8:    
    .ascii "\name"
9:    
    .p2align 1, 0x20
\label:
11:
    .set _last_, _list_
    .set _list_, _last_ + (11b - 10b + 1)
.endm

;----------------------------------------------------------------------
; little endian !!! AVR
;
;    A    Z (r31:r30) is used as generic address pointer, deed by avr ISA
;
;    RSP  Y (r29:r28) used as return stack pointer    
;    PSP  X (r27:r26) used as data/parameter stack pointer
;    TOS  T (r25:r24) used as top in stack
;    NOS  N (r22:r23) used as second in stack
;    WRK  W (r20:r21) used as work
;    IPT  I (r18:r19) used as instruction pointer
;
;   all stacks grows downwards.
;
;----------------------------------------------------------------------
;    push into return stack, 
.macro rspush low, high 
    st -X, \low
    st -X, \high
.endm

;----------------------------------------------------------------------
;    pull from return stack, 
.macro rspull low, high
    ld \high, X+
    ld \low, X+
.endm

;----------------------------------------------------------------------
;    push into data stack, 
.macro pspush low, high
    st -Y, \low
    st -Y, \high
.endm

;----------------------------------------------------------------------
;    pull from data stack, 
.macro pspull low, high
    ld \high, Y+
    ld \low, Y+
.endm

;----------------------------------------------------------------------
;    load a word from program memory (flash)
;    ( only works with TWO lpm !!! )
;    Z address in bytes!
.macro pmload low, high
    lsl zpm_low
    rol zpm_high
    lpm \low, Z+
    lpm \high, Z+
    ror zpm_high
    ror zpm_low
.endm

;----------------------------------------------------------------------
;    load from static memory (sram), increments pointer
;
.macro srload byte
    ld \byte, Z+
.endm

;----------------------------------------------------------------------
;    save to static memory (sram), increments pointer
;
.macro srsave byte
    st Z+, \byte 
.endm

;----------------------------------------------------------------------
;
; for Atmega8:
;

;----------------------------------------------------------------------
; all primitives must start bellow init_
;

.macro POON
;	for atmega8 could use rjmp
    jmp _next
.endm

;**********************************************************************
;  constant values
;
;    %s/#define *\([^ ]*\) */ \1 = /
;    %s/ *\([^ ]*\) *= */#define \1 /

;----------------------------------------------------------------------
;    sizes
;
; "Column 72 means Continue", 72 always \0
; Readability is good standart is 80
;
TIB_SIZE = 80

; PAD minimum size
;
PAD_SIZE = TIB_SIZE

; HDS minimum size, 16bits (16*2+2) +2 
;
HDS_SIZE = 36

; stacks 18 words deep. WISE as M00re said.
;
STACK_SIZE = 36

; default cell size
;
CELL_SIZE = 2

; maximum word size
;
WORD_SIZE = 15

; default base
;
BASE_DEFAULT = 16

;----------------------------------------------------------------------
;   words can be 1 to 15 chars lenght, 
;
;   almost over for normal english ~10 letters words 
;   http://norvig.com/mayzner.html
;
;   flags 
;
;   tradicional:
;
;   IMMEDIATE, COMPILE, SMUDGE, LEAP
;
;   IMMEDIATE is mandatory execute words.
;
;   COMPILE is for compile only words.
;
;   HIDDEN or SMUDGE is not used, free to reassign any words but not change already compliled
;
;   LEAP is to mark as pure assembler routines, no calls inside.
;
;   RESERVED as 0x80, marks the byte as size+flag byte and allow
;   backtrace to name from execute address, names are ASCII < 0x80
;
;   if need 32 chars ANSI names, forget HIDDEN
;
F_RESERVED = 0x80
F_IMMEDIATE = 0x40
F_COMPILE = 0x20
F_HIDDEN = 0x10

F_TOMASK = 0xF0
F_UNMASK = 0x0F

; not flags but usefull to remember
F_LEAP = 0x00	; for primitives, pure assembler no calls for forth words
F_CORE = 0x00	; for core words

;---------------------------------------------------------------------
;
; minimal error codes from forth 2012
;
NO_ERROR = 0
INVALID_MEMORY = -9
OUT_OF_RANGE = -11
INVALID_WORD = -13
TO_READ_ONLY = -20
NOT_A_NUMBER = -24

;---------------------------------------------------------------------
; ASCII constants
;
; Flow Control
; assumes that all line edit is done at remote!
; no backspace, no delete, no moving cursor, just a static line.
; works as a screen or block, just receives a line till a CR or CR LF
; uses BS, for edit last char
;
;NAK_   =   0x15    ; ascii NAK ^U

XON_   =   0x11    ; ascii DC1 ^Q
XOFF_  =   0x13    ; ascii DC3 ^S

CR_    =   0x0d    ; ascci carriage return ^M
LF_    =   0x0a    ; ascii line feed ^J
TB_    =   0x09    ; ascii horizontal tab ^I
VT_    =   0x0b    ; ascii vertical tab ^K, somewhere also used as CR/LF 
BS_    =   0x08    ; ascii backspace ^H
BL_    =   0x20    ; ascii space 

QT_    =   0x22    ; quotation mark "

;----------------------------------------------------------------------
; AVR SREG constants
;

BIT_CARRY = 0

BIT_ZERO = 1

BIT_NEG = 2

;----------------------------------------------------------------------

#ifdef atmega8

; atmega8 have flash memory of 128 pages of 32 words

SPM_SIZE = 64

SRAM_START = 0x060  ; SRAM from AVR manual

SRAM_END = 0x45F    ; SRAM from AVR manual 

FLASH_RWW = 0x0000

FLASH_NRWW = 0x1E00    ; using optiboot in 512 bytes !!!!

FLASH_END = 0x1FFF 

E2P_END = 0x1FF

#endif

#ifdef atmega328

; atmega328 have flash memory of 256 pages of 64 words

SPM_SIZE = 128

SRAM_START = 0x0100  ; SRAM from AVR manual

SRAM_END = 0x08FF  ; SRAM from AVR manual

FLASH_RWW = 0x0000

FLASH_NRWW = 0x3E00    ; using optiboot in 512 bytes !!!!

FLASH_END = 0x3FFF 

E2P_END = 0x3FF

#endif

/* for eeprom use */

E2P_PAGESIZE = 4

E2P_START = 0x000

/* avr signature bytes */

SIGNATURE_000	= 0x1e
SIGNATURE_001	= 0x95

; for atmega328
SIGNATURE_002	= 0x0f
; for atmega328P
SIGNATURE_003	= 0x0f
; for atmega328PB
SIGNATURE_004	= 0x16

/* task states, QNX */

HALT = 0x0
IDLE = 0x1
BUSY = 0x2
WAIT = 0x3

GIVE = 0x4
TAKE = 0x8

;----------------------------------------------------------------------
/* temporary where start forth */

;----------------------------------------------------------------------
