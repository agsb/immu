/*

pre-compiled words, for minimal interactive

words, most from FIG-FORTH PDP-11 "classic"

*/
#---------------------------------------------------------------------- 
# ok  
header  "[", "LBRAC", 
    .word DOCON, 0, STATE, TO, ENDS 
 
#---------------------------------------------------------------------- 
# ok  
header  "]", "RBRAC", 
    .word DOCON, 1, STATE, TO, ENDS 
 
#---------------------------------------------------------------------- 
# ok  create a dictionary header with next word in 'TIB', not update latest link
header  "CREATE", "create", 
    .word CREATE, ENDS 
 
#---------------------------------------------------------------------- 
# ok  ends a word definition, update latest link
header  "FINITE", "create", 
    .word CREATE, ENDS 
 
#---------------------------------------------------------------------- 
# ok  
header  ":", "COLON", 
    .word CREATE, RBRAC, ENDS 
 
#---------------------------------------------------------------------- 
# ok  
header  ";", "SEMMI", 
    .word FINITE, LBRAC, ENDS 
  
#---------------------------------------------------------------------- 
# ok BACK 
header  "BACK", "BACK", F_IMMEDIATE 
    .word HERE, SWAP, MINUS, COMMA, ENDS 
 
#---------------------------------------------------------------------- 
# ok MARK 
header  "MARK", "MARK", F_IMMEDIATE 
    .word HERE, 0, COMMA, ENDS 
 
#---------------------------------------------------------------------- 
# ok BEGIN 
header  "BEGIN", "BEGIN", F_IMMEDIATE 
    .word HERE, ENDS 
 
#---------------------------------------------------------------------- 
# ok AGAIN resolves a backward branch 
header  "AGAIN", "AGAIN", F_IMMEDIATE 
    .word COMP, BRANCH, BACK, ENDS 
 
#---------------------------------------------------------------------- 
# ok UNTIL 
header  "UNTIL", "UNTIL", F_IMMEDIATE 
    .word COMP, ZBRANCH, BACK, ENDS 
 
#---------------------------------------------------------------------- 
# ok UNLESS 
header  "UNLESS", "UNLESS", F_IMMEDIATE 
    .word INVERT, UNTIL, ENDS 
 
#---------------------------------------------------------------------- 
# 
# ok IF 
header  "IF", "IF", F_IMMEDIATE 
    .word COMP, ZBRANCH, MARK, ENDS 
 
#---------------------------------------------------------------------- 
# 
# ok ENDIF resolves a forward branch 
header  "ENDIF", "ENDIF", F_IMMEDIATE 
    .word DUP, HERE, MINUS, SWAP, TO, ENDS 
 
#---------------------------------------------------------------------- 
# 
# ok THEN 
header  "THEN", "THEN", F_IMMEDIATE 
    .word ENDIF, ENDS 
 
#---------------------------------------------------------------------- 
# 
# ok ELSE 
header  "ELSE", "ELSE", F_IMMEDIATE 
    .word COMP, BRANCH, MARK, SWAP, ENDIF, ENDS 
 
#---------------------------------------------------------------------- 
# 
# ok WHILE 
header  "WHILE", "WHILE", F_IMMEDIATE 
    .word IF, ENDS 
 
#---------------------------------------------------------------------- 
# 
# ok REPEAT 
header  "REPEAT", "REPEAT", F_IMMEDIATE 
    .word TOR, TOR, AGAIN, RAT, RAT, MINUS, ENDIF, ENDS 
 
#---------------------------------------------------------------------- 

#ok Hex
header	"HEX", "hex",
	.word docon, 16, RADX, TO, ENDS

#ok decimal
header	"DECIMAL", "dec",
	.word docon, 10, RADX, TO, ENDS

#ok Hex
header	"OCTAL", "oct",
	.word docon, 8, RADX, TO, ENDS

#---------------------------------------------------------------------- 


#ok <BUILDS
header	"<BUILDS", "builds"
	.word docon, 0, ENDS

#ok DOES> 
header	"DOES>", "does"
	.word docon, 0, ENDS

/*
        HEAD    210,CONSTANT,240,CON,DOCOL              ; ***** CONSTANT
        .WORD   CREAT,SMUDG,COMMA,PSCOD
DOCON:  MOV     (W),-(S)
        NEXT
;
        HEAD    210,VARIABLE,240,VAR,DOCOL              ; ***** VARIABLE
        .WORD   CON,PSCOD
DOVAR:  MOV     W,-(S)
        NEXT
;
        HEAD    207,^/<BUILDS/,323,BUILD,DOCOL          ; ***** <BUILDS
;  CREATE NEW DATA TYPE WITH CODE ROUTINE IN HIGHER-LEVEL FORTH.
        .WORD   ZERO,CON,SEMIS
;
        HEAD    205,DOES>,276,DOES,DOCOL                ; ***** DOES>
        .WORD   FROMR,LATES,PFA,STORE,PSCOD
DODOE:  MOV     IP,-(RP)
        MOV     (W)+,IP
        MOV     W,-(S)
        NEXT
*/



