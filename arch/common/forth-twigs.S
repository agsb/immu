
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

;---------------------------------------------------------------------
;
;    A small Forth for ATmega8 
;
;---------------------------------------------------------------------
; dictionary structure 
;
; cell size is a word of 16 bits 
;
; .word  link    link to previous 
; .byte  size    sizeof name OR flags 
; .ascii "name"  name, plus a pad byte with BL (0x32) if size is even 
; .word  param,  many references 
;
;----------------------------------------------------------------------
 
;
; classics 
;
.NOLIST 
.LIST 
 
;********************************************************************** 
; FORTH
;
;    the follow definitions of compound words 
;    are as already compiled into a list of references, 
;    that is a sequence of cells. 
;    No preorder because the assembler does translation 
;    of names to address (references) 
;
;    (some adapted from old fig-forth and eforth istings) 
;
;********************************************************************** 

;----------------------------------------------------------------------
;
; ok ( w a -- ) 
;	w = b1b2 ~~ [a] = b1, [a+1] = b2
; just write a word
;
HEADER "E!", "ETO", F_LEAP
    .word OVER, OVER, ECTO, ONE, PLUS, TOR, ENDIAN, RTO, ECTO, ENDS   

;----------------------------------------------------------------------
;
; ok ( a -- w ) 
;   [a] = b1, [a+1] = b2 ~~ w = b1b2
;   w1 0x00ff and, w2 0x00ff and, 
;   w1 = b100, w2 = b300, w2 endian, w2 = 00b3
;   w1 w2 or
;
HEADER "E@", "EAT", F_LEAP
    .word DUP, ECAT, SWAP, ECAT
    .word LIT, 0x00FF, AND
    .word ENDIAN, SWAP
    .word LIT, 0x00FF, AND
    .word OR, ENDS

;********************************************************************** 
;
;   stack words
;
;----------------------------------------------------------------------
;
; ok ( w2 w1 -- w1 ) 
;
HEADER "NIP", "NIP",
    .word SWAP, DROP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 -- w2 w3 w1 ) 
;
HEADER "SWIP", "SWIP",
    .word TOR, SWAP, RTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 -- w2 w1 w2 ) 
; moved to primitives
;HEADER "OVER", "OVER",
;    .word TOR, DUP, RTO, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 -- w2 w1 w3 ) 
;
HEADER "ROT", "ROTU",
    .word SWIP, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 -- w1 w3 w2 ) 
;
HEADER "-ROT", "ROTD",
    .word SWAP, SWIP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w2 w1 --  w1 w2 w1 ) 
;
HEADER "TUCK", "TUCK",
    .word SWAP, OVER, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w3 w2 w1 --  w1 w2 w3 ) 
;
HEADER "FLIP", "FLIP",
    .word SWAP, SWIP, SWAP, ENDS 

;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1) 
;
HEADER "=", "EQUAL",
    .word MINUS, ZEQU, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1) 
;
HEADER "<>", "NOTEQUAL",
    .word EQUAL, INVERT, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- 0 | -1 ) 
; w1 > w2
HEADER ">", "GTHAN",
    .word SWAP, LTHAN, ENDS 
 
;----------------------------------------------------------------------
;  ok 0>  must be signed 
;
HEADER "0>", "ZEROGT",
     .word ZERO, LTHAN, ENDS 
 
;----------------------------------------------------------------------
;  ok 0< must be signed 
;
HEADER "0<", "ZEROLT",
    .word ZERO, SWAP, LTHAN, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w * CELL  ) 
; CELL is 2, multiply by 2, easy way 
;
HEADER "CELLS", "CELLS",
    .word SHL, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + CELL ) 
;
HEADER "CELL+", "CELLPLUS",
    .word CELL, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - CELL ) 
;
HEADER "CELL-", "CELLMINUS",
    .word CELL, MINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + 1 ) 
;
HEADER "1+", "ONEPLUS",
     .word ONE, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - 1 ) 
;
HEADER "1-", "ONEMINUS",
     .word ONE, MINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + 2 ) 
;
HEADER "2+", "TWOPLUS",
     .word TWO, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - 2 ) 
;
HEADER "2-", "TWOMINUS",
     .word TWO, MINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( u w -- ) 
;
HEADER "+!", "PLUSTO",
    .word DUP, TOR, AT, PLUS, RTO, TO, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + 1 ) 
;
HEADER "CHAR+", "CHARPLUS",
    .word ONEPLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - 1 ) 
;
HEADER "CHAR-", "CHARMINUS",
    .word ONEMINUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w ) 
;   char is 1, then does nothing
;
HEADER "CHARS", "CHARS",
    .word ENDS 
 
;********************************************************************** 
;
;    load variables 
;
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "TIB", "TIB",
    .word LIT, TIB0, ENDS
    POON 
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "STATE", "STATE",
    .word LIT, STAT, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "BASE", "BASE",
    .word LIT, BASE, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;   keep PS for checks
HEADER "CSP", "CSP",
    .word LIT, CSPP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "EP", "EPP",
    .word LIT, VEP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "DP", "DPP",
    .word LIT, VDP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "HP", "HPP",
    .word LIT, VHP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
; stack for variables from end of stacks
;
HEADER "UP", "UPP",
    .word LIT, VUP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
; buffer for user, att not updates UP
;
HEADER "BUFF", "BUFF",
    .word UPP, SWAP, MINUS, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
; buffer for user, shares variables
;
HEADER "PAD", "PAD",
    .word LIT, PAD_SIZE, BUFF, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
;HEADER "RS$", "RSIS",
;    .word LIT, RS0, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
;HEADER "PS$", "PSIS",
;    .word LIT, PS0, ENDS
 

;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "DEPTH", "DEPTH",
    .word PSAT, LIT, PS0, MINUS, ENDS
 
;----------------------------------------------------------------------
;
; ok ( -- w) 
;
HEADER "RDEPTH", "RDEPTH",
    .word RSAT, LIT, RS0, MINUS, ENDS
 

;********************************************************************** 
; 
;   vocabulary words
;
;   just a hook, not using, in AVR only one vocabulary
;
;----------------------------------------------------------------------
HEADER "CURRENT", "CURRENT",
    .word LIT, CURR, ENDS

;----------------------------------------------------------------------
HEADER "CONTEXT", "CONTEXT",
    .word LIT, CTXT, ENDS

;----------------------------------------------------------------------
HEADER "DEFINITIONS", "DEFINITIONS",
    .word CONTEXT, AT, CURRENT, TO, ENDS

;----------------------------------------------------------------------
HEADER "LATEST", "LATEST",
    .word LIT, LAST, ENDS
 
;********************************************************************** 
; 
;   basic words
;
;----------------------------------------------------------------------
;   strange changes ?
;   all compilation is done in sram, then need a trick
;
;   up is a pointer to next free cell in sram, from the end of TIB
;   dp is a pointer to next free cell in flash
;   hp is a pointer to next free cell in sram, syncronous with dp 
;
;   here return where dp is, used for absolute branch and zbranch,
;   uhere returns where hp is, used for place in sram,
;   comma writes in sram, and allot updates up and dp pointers
;   when done to write sram to flash
;
;----------------------------------------------------------------------
;
; ok HERE ( -- w ) 
;
HEADER "UHERE", "UHERE",
    .word HPP, AT, ENDS 
 
;----------------------------------------------------------------------
;
; ok HERE ( -- w ) 
;
HEADER "HERE", "HERE", F_CORE
    .word DPP, AT, ENDS 
 
;----------------------------------------------------------------------
;
; ok ALLOT ( u -- ) 
; not standart: updates DP and UP
 
HEADER "ALLOT", "ALLOT", F_CORE
    .word DUP
    .word HPP, AT, PLUS, HPP, TO 
    .word DPP, AT, PLUS, DPP, TO 
    .word ENDS 
 
;----------------------------------------------------------------------
;
; is ALIGN 
; not standart: updates DP and UP
;
HEADER "ALIGN", "ALIGN", F_CORE
    .word HPP, AT, ALIGNED, HPP, TO
    .word DPP, AT, ALIGNED, DPP, TO
    .word ENDS 
 
;----------------------------------------------------------------------
;
; ok CCOMMA ( w -- ) 
;
HEADER "C,", "CCOMMA", F_IMMEDIATE | F_CORE
    .word UHERE, CTO, ONE, ALLOT, ENDS 
 
;----------------------------------------------------------------------
;
; ok COMMMA ( w -- ) 
;
HEADER ",", "COMMA", F_IMMEDIATE | F_CORE
    .word UHERE, TO, CELL, ALLOT, ENDS 
 
;----------------------------------------------------------------------
;
; ok TOMMA ( a2 a1 -- ) 
; not standart, no updates DP or UP, 
;   just do TO (a2 a1-a2+UP -- )
;
HEADER "<,", "TOMMA", F_IMMEDIATE
    .word OVER, MINUS, UHERE, PLUS, TO, ENDS 
 
;-------------------------------------'---------------------------------
;
; is DOVAR ( -- a ), place the address of next cell into stack, 
;   R> DUP 2+ >R
;
;	note: the address is at flash, then if is a reference to a value
;	it must be de-referenced to sram 
;	      
HEADER "DOVAR", "DOVAR",
    .word RTO, DUP, CELL, PLUS, TOR, ENDS 
 
;-------------------------------------'---------------------------------
;
; is DOCON ( -- a ), place the contents of next cell into stack, 
;   R> DUP 2+ >R @
;
;	note: the address is at flash, then if is a reference
;   to a value, it must be de-referenced (ATAT) to sram 
;
HEADER "DOCON", "DOCON",
    .word DOVAR, ATAT, AT, ENDS 

;----------------------------------------------------------------------
;
; is LITERAL ( w -- ) 
;
HEADER "LITERAL", "LITERAL", F_CORE
    .word LIT, LIT, COMMA, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok this puts next cell into stack and compiles into HERE 
; used only in precompiled sources as forth-twigs
; 
HEADER "COMP", "COMP", F_IMMEDIATE
    .word RTO, DUP, CELLPLUS, TOR, ATAT, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok compile a eow 
;
HEADER "EXIT", "EXIT", F_IMMEDIATE
    .word COMP, ENDS, ENDS

;----------------------------------------------------------------------
;
; ok execute xt from tos
;
HEADER "EXECUTE", "EXEC", F_IMMEDIATE
    .word TOR, ENDS

;----------------------------------------------------------------------
;
; ok make a word recursive 
; recursive return to last 
;
HEADER "RECURSE", "RECURSE", 
    .word RAT, CELL, MINUS, TOR, ENDS

;----------------------------------------------------------------------
;
; Control words review. BRANCH and ZBRANCH are absolute references.
;
;----------------------------------------------------------------------
 
;----------------------------------------------------------------------
;
; ok MARKTO 
; places a address of cell
; places to address to self in a holder, 
; and left address of holder at stack
;
HEADER "MARKTO", "MARKTO", F_IMMEDIATE | F_COMPILE,
    .word HERE, DUP, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok TOMARK 
; places a address of cell 
; resolves a back reference to last holder 
; and places a address to self at holder 
HEADER "TOMARK", "TOMARK", F_IMMEDIATE | F_COMPILE,
    .word HERE, SWAP, TOMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok BEGIN 
;
HEADER "BEGIN", "BEGIN", F_IMMEDIATE | F_COMPILE,
    .word HERE, ENDS 
 
;----------------------------------------------------------------------
;
; ok AGAIN resolves a unconditional branch 
;
HEADER "AGAIN", "AGAIN", F_IMMEDIATE | F_COMPILE,
    .word COMP, BRANCH, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok UNTIL resolves a conditional branch, as C do { ... } while (0) 
;
HEADER "UNTIL", "UNTIL", F_IMMEDIATE | F_COMPILE,
    .word COMP, ZBRANCH, COMMA, ENDS 
 
;----------------------------------------------------------------------
;
; ok UNLESS 
;
HEADER "UNLESS", "UNLESS", F_IMMEDIATE | F_COMPILE, 
    .word ZEQU, UNTIL, ENDS 
 
;----------------------------------------------------------------------
;
; ok IF (executed if tos is not zero)
;
HEADER "IF", "IF", F_IMMEDIATE | F_COMPILE,
    .word COMP, ZBRANCH, MARKTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok GO (executed ever)
;
HEADER "GO", "GO", F_IMMEDIATE | F_COMPILE,
    .word COMP, BRANCH, MARKTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok THEN 
;
HEADER "THEN", "THEN", F_IMMEDIATE | F_COMPILE,
    .word ENDIF, ENDS 
 
;----------------------------------------------------------------------
;
; ok ENDIF resolves a forward branch 
;
HEADER "ENDIF", "ENDIF", F_IMMEDIATE | F_COMPILE,
    .word TOMARK, ENDS 
 
;----------------------------------------------------------------------
;
; ok ELSE (executed if tos is zero)
;
HEADER "ELSE", "ELSE", F_IMMEDIATE | F_COMPILE,
    .word GO, SWAP, TOMARK, ENDS 
 
;----------------------------------------------------------------------
;
; ok WHILE 
;
HEADER "WHILE", "WHILE", F_IMMEDIATE | F_COMPILE,
    .word IF, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok REPEAT 
;
HEADER "REPEAT", "REPEAT", F_IMMEDIATE | F_COMPILE,
    .word AGAIN, TOMARK, ENDS 
 
 
;----------------------------------------------------------------------
; @eforth
; is AHEAD (a forward goto)
;
HEADER "AHEAD", "AHEAD", F_IMMEDIATE | F_COMPILE,
    .word GO, ENDS 
 
;----------------------------------------------------------------------
; @eforth
; is AFT 
;
HEADER "AFT", "AFT", F_IMMEDIATE | F_COMPILE,
    .word DROP, GO, HERE, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; is HOOK 
;
HEADER "HOOK", "HOOK", F_IMMEDIATE | F_COMPILE,
    .word BEGIN, TOR, ENDS 
 
;----------------------------------------------------------------------
;
; is BACK 
;
HEADER "BACK", "BACK", F_IMMEDIATE | F_COMPILE,
    .word RTO, AGAIN, ENDS 
 
;----------------------------------------------------------------------
;
; is ?BACK 
;
HEADER "?BACK", "QBACK", F_IMMEDIATE | F_COMPILE,
    .word RTO, UNTIL, ENDS 
 
;----------------------------------------------------------------------
;
; is FOR ( u -- h ; -- u )
; count down, from +32767
HEADER "FOR", "FOR", F_IMMEDIATE
    .word COMP, TOR, BEGIN, ENDS 
 
;----------------------------------------------------------------------
;
; is TXEN ( -- ; -- u ) 
;
HEADER "TXEN", "TXEN", 
    .word RTO, ONEMINUS
    .word DUP, ZBRANCH, 1f  
    .word TOR 
1:  .word ENDS

;----------------------------------------------------------------------
;
; is NEXT ( h -- ) R:( -- h u ) 
;
HEADER "NEXT", "NEXT", F_IMMEDIATE
    .word COMP, TXEN, UNLESS, ENDS

;----------------------------------------------------------------------
; rever zzzz
/*
\ CASE's implementation imported from Gforth.
\
\ Usage
\ ( n )
\ CASE
\    1 OF .... ENDOF
\    2 OF .... ENDOF
\    OTHERWISE
\ END-CASE
\
\ Remember not to consume the element in the OTHERWISE case.
*/
;----------------------------------------------------------------------
;
; is CASE ( a -- )
;
HEADER "CASE", "CASE", F_IMMEDIATE
    .word ZERO, ENDS

;----------------------------------------------------------------------
;
; is OF ( -- )
;
HEADER "OF", "OF", F_IMMEDIATE
    .word ONEPLUS, COMP, OVER, COMP, EQUAL, COMP, IF, COMP, DROP, ENDS

;----------------------------------------------------------------------
;
; is ENDOF ( -- )
;
HEADER "ENDOF", "ENDOF", F_IMMEDIATE
    .word COMP, ELSE, ENDS

;----------------------------------------------------------------------
;
; is DEFAULT ( -- )
;
HEADER "DEFAULT", "DEFAULT", F_IMMEDIATE
    .word COMP, FTRUE, COMP, IF, COMP, DROP, ENDS

;----------------------------------------------------------------------
;
; is ENDCASE ( n -- ) 
;
HEADER "ENDCASE", "ENDCASE", F_IMMEDIATE
    .word COMP, DROP 
    .word FOR, COMP, THEN, NEXT, ENDS

;----------------------------------------------------------------------
;
; is DOIT ( n m -- ; -- m+0x8000 m+0x8000-n ) 
; counts from n to m
HEADER "DOIT", "DOIT", 
    ; forth-83 0x8000 trick
    .word LIT, 0x8000, PLUS, DUP, TOR, MINUS, TOR, ENDS

;----------------------------------------------------------------------
;
; is LOOPN ( k -- true | false ; m n -- m n+k ) 
;
HEADER "+LOOPI", "LOOPN", 
    .word RTO, PLUS, RTO, OVER, OVER ; ( n+k m k )
    .word LTHAN, ZBRANCH, 6f
4:  
    .word RTO, RTO, FTRUE, ENDS
6:  
    .word DROP, DROP, FFALSE, ENDS 

;----------------------------------------------------------------------
;
; is LOOPI ( k -- f ; m n -- m n+k false | true) 
;
HEADER "LOOPI", "LOOPI", 
    .word ONE, LOOPN, ENDS

;----------------------------------------------------------------------
;
; is DO ( n m -- ; --  m n ) 
; counts from n to m
;
HEADER "DO", "DO", F_IMMEDIATE
    .word COMP, DOIT, BEGIN, ENDS

;----------------------------------------------------------------------
;
; is I (  -- n ; m n -- m n ) 
;
HEADER "I", "I", 
    .word RTO, DUP, TOR, ENDS

;----------------------------------------------------------------------
;
; is j (  -- n ; m n -- m n ) 
;
HEADER "J", "J", 
    .word RTO, RTO, RTO, DUP, TOR, SWAP, TOR, SWAP, TOR, ENDS

;----------------------------------------------------------------------
;
; is LEAVE ( n m -- ; -- n m ) 
;   old way, runs last one
;
HEADER "LEAVE", "LEAVE", F_IMMEDIATE
    .word UNLOOP, EXIT, ENDS

;----------------------------------------------------------------------
;
; is LOOP ( -- ; -- m n+1 ) 
;
HEADER "LOOP", "LOOP", F_IMMEDIATE
    .word COMP, LOOPI, UNTIL, ENDS

;----------------------------------------------------------------------
;
; is LOOP ( k -- ; -- m n+k ) 
;
HEADER "+LOOP", "PLOOP", F_IMMEDIATE
    .word COMP, LOOPN, UNTIL, ENDS

;----------------------------------------------------------------------
;
; is UNLOOP ( -- ; -- m n+1 ) 
;
HEADER "UNLOOP", "UNLOOP", F_IMMEDIATE
    .word RTO, RTO, DROP, DROP, ENDS

;**********************************************************************
;----------------------------------------------------------------------
;
; is  ( a u -- )
;
HEADER "BL", "BL",
    .word LIT, 0x20, EMIT, ENDS

;----------------------------------------------------------------------
;
; is  ( a u -- )
;
HEADER "CR", "CR",
    .word LIT, 0x0D, EMIT, ENDS

;----------------------------------------------------------------------
;
; is  ( a u -- )
;
HEADER "LF", "LF",
    .word LIT, 0x0A, EMIT, ENDS

;----------------------------------------------------------------------
;
; is  ( a u -- )
; it is used as CR/LF in databases and some file formats
;
HEADER "PACE", "PACE",
    .word LIT, 0x0B, EMIT, ENDS

;----------------------------------------------------------------------
;
; is  ( a u -- )
;
HEADER "BELL", "BELL",
    .word LIT, 0x07, EMIT, ENDS

;---------------------------------------------------------------------- 
; 
; is SPACE ( -- )
; 
HEADER "SPACE", "SPACE" 
    .word LIT, 0x20, EMIT, ENDS 
 
;---------------------------------------------------------------------- 
; 
; is SPACES ( n -- )
;   emits until 0
HEADER "SPACES", "SPACES" 
1:  .word ZDUP, ZBRANCH, 2f
    .word SPACE, ONEMINUS, BRANCH, 1b
2:  .word ENDS 
 
;---------------------------------------------------------------------- 
; 
; is COUNT ( c-addr -- c-addr+1 c ) 
; convert counted string c-addr to address and count
HEADER "COUNT", "COUNT", 
    .word DUP, AT, TOR, ONEPLUS, RTO, ENDS 
 
;----------------------------------------------------------------------
;
; is  ( a u -- )
;
HEADER "TYPE", "TYPE",
1:  .word DUP, ZBRANCH, 2f
    .word ONEMINUS, TOR, DUP, AT, EMIT, ONEPLUS, RTO
    .word BRANCH, 1b
2:  .word DROP, DROP, ENDS 
  
;----------------------------------------------------------------------
;
; is  ( u1 u2 -- u3 )
;
HEADER "UM-", "UMMINUS",
    .word NEGATE, UMPLUS, ENDS

;**********************************************************************
;----------------------------------------------------------------------
;
HEADER "COLD0", "COLDZERO", F_LEAP
    
    .word LIT, 0x0000, LIT, VOID, TO 
    .word LIT, 0x0000, LIT, LIVE, TO 
    .word LIT, 0x0000, LIT, TURN, TO 
    .word LIT, 0x0000, LIT, REST, TO 

    .word LIT, ZZZZ, LIT, LAST, TO 
    .word LIT, free_flash, LIT, VDP, TO
    .word LIT, EP0, LIT, VEP, TO

    .word LIT, UH0, LIT, VHP, TO
    .word LIT, US0, LIT, VUP, TO
    .word ENDS

;----------------------------------------------------------------------
;
HEADER "EELOAD", "EELOAD", F_LEAP
    .word ZERO, DUP, EAT, LIT, VOID, TO 
    .word TWO, PLUS, DUP, EAT, LIT, LIVE, TO 
    .word TWO, PLUS, DUP, EAT, LIT, TURN, TO 
    .word TWO, PLUS, DUP, EAT, LIT, REST, TO 

    .word TWO, PLUS, DUP, EAT, LIT, LAST, TO 
    .word TWO, PLUS, DUP, EAT, LIT, VDP, TO 
    .word TWO, PLUS, DUP, EAT, LIT, VEP, TO 
    .word TWO, PLUS, DUP, EAT, LIT, VUP, TO 
    .word ENDS

;----------------------------------------------------------------------
;
HEADER "EESAVE", "EESAVE", F_LEAP
    .word ZERO, DUP, LIT, VOID, AT, SWAP, ETO 
    .word TWO, PLUS, DUP, LIT, LIVE, AT, SWAP, ETO 
    .word TWO, PLUS, DUP, LIT, TURN, AT, SWAP, ETO 
    .word TWO, PLUS, DUP, LIT, REST, AT, SWAP, ETO 

    .word TWO, PLUS, DUP, LIT, LAST, AT, SWAP, ETO 
    .word TWO, PLUS, DUP, LIT, VDP, AT, SWAP, ETO 
    .word TWO, PLUS, DUP, LIT, VEP, AT, SWAP, ETO 
    .word TWO, PLUS, DUP, LIT, VUP, AT, SWAP, ETO 
    .word ENDS

;----------------------------------------------------------------------
;
HEADER "COLD", "COLD", F_LEAP
    .word EELOAD
    .word LIT, LIVE, ZEQU, ZBRANCH, _safe
    .word COLDZERO, EESAVE  
_safe:    
    .word LIT, RS0, RSTO
    .word LIT, PS0, PSTO
    .word LIT, 0x00, STATE, TO
    .word LIT, 0x10, BASE, TO
    .word LIT, WARM, RTO
    .word LIT, LIVE, DUP, AT, ONE, PLUS, SWAP, TO 
    .word ENDS 
 
;----------------------------------------------------------------------
;
HEADER "WARM", "WARM", F_LEAP
    ; verify error code 
    ; resets etc 
    .word LIT, TURN, AT, EXEC, QUIT, ENDS 
 
;----------------------------------------------------------------------
; does reset 
;
HEADER "BYE", "BYE", F_LEAP
    .word EESAVE
    .word LIT, REST, AT, EXEC, RESET, ENDS 

