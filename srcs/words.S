/*

pre-compiled words, for minimal interactive

words, most from fig-forth pdp-11 "classic"

*/

#---------------------------------------------------------------------- 
# ok  must continue later
header  "ZZZZ", "zzzz", 
    .word ends 

#---------------------------------------------------------------------- 
# ok  must continue later
header  "ALLOT", "allot",
    .word dp, plusto, ends
    
#---------------------------------------------------------------------- 
# ok  must continue later
header  "HERE", "here",
    .word dp, at, ends

#---------------------------------------------------------------------- 
# ok  push a cell onto dictionary
header  ",", "comma",
    .word here, to, CELL, allot, ends

#---------------------------------------------------------------------- 
# ok  push a byte onto dictionary
header  "C,", "ccomma",
    .word here, cto, BYTE, allot, ends

#---------------------------------------------------------------------- 
# ok  does a entry in dictionary, does not update latest.
# zzzz needs fill pads ?
header  "ENTRY", "entry", 
    .word latest, at, comma, 0, ccomma, cscan, dup, ccomma, 
    .word dup, tor, here, rot, rot, cmove, rto, allot, 
    .word dp, dup, aligned, minus, dp, to, ends 

#---------------------------------------------------------------------- 
# ok  
header  "[", "lbrac", 
    .word docon, 0, state, to, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  "]", "rbrac", 
    .word docon, 1, state, to, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  "CONSTANT", "constant", 
    .word create, zzzz, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  "VARIABLE", "variable", 
    .word create, zzzz, ends 

#---------------------------------------------------------------------- 
# ok  create a dictionary entry with next word in 'tib', not update latest link
header  "CREATE", "create", 
    .word create, zzzz, ends 
 
#---------------------------------------------------------------------- 
# ok  ends a dictionary entry, update latest link
header  "FINITE", "create", 
    .word create, zzzz, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  ":", "colon", 
    .word create, rbrac, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  ";", "semmi", 
    .word finite, lbrac, ends 
  
#---------------------------------------------------------------------- 
# ok back 
header  "BACK", "back", f_immediate 
    .word here, swap, minus, comma, ends 
 
#---------------------------------------------------------------------- 
# ok mark 
header  "MARK", "mark", f_immediate 
    .word here, 0, comma, ends 
 
#---------------------------------------------------------------------- 
# ok begin 
header  "BEGIN", "begin", f_immediate 
    .word here, ends 
 
#---------------------------------------------------------------------- 
# ok again resolves a backward branch 
header  "AGAIN", "again", f_immediate 
    .word comp, branch, back, ends 
 
#---------------------------------------------------------------------- 
# ok until 
header  "UNTIL", "until", f_immediate 
    .word comp, zbranch, back, ends 
 
#---------------------------------------------------------------------- 
# ok unless 
header  "UNLESS", "unless", f_immediate 
    .word invert, until, ends 
 
#---------------------------------------------------------------------- 
# 
# ok if 
header  "IF", "if", f_immediate 
    .word comp, zbranch, mark, ends 
 
#---------------------------------------------------------------------- 
# 
# ok endif resolves a forward branch 
header  "ENDIF", "endif", f_immediate 
    .word dup, here, minus, swap, to, ends 
 
#---------------------------------------------------------------------- 
# 
# ok then 
header  "THEN", "then", f_immediate 
    .word endif, ends 
 
#---------------------------------------------------------------------- 
# 
# ok else 
header  "ELSE", "else", f_immediate 
    .word comp, branch, mark, swap, endif, ends 
 
#---------------------------------------------------------------------- 
# 
# ok while 
header  "WHILE", "while", f_immediate 
    .word if, ends 
 
#---------------------------------------------------------------------- 
# 
# ok repeat 
header  "REPEAT", "repeat", f_immediate 
    .word tor, tor, again, rat, rat, minus, endif, ends 
 
#---------------------------------------------------------------------- 

#ok hex
header	"HEX", "hex",
	.word docon, 16, radx, to, ends

#ok decimal
header	"DECIMAL", "dec",
	.word docon, 10, radx, to, ends

#ok hex
header	"OCTAL", "oct",
	.word docon, 8, radx, to, ends

#---------------------------------------------------------------------- 


#ok <builds
header	"<BUILDS", "builds"
	.word docon, 0, ends

#ok does> 
header	"DOES>", "does"
	.word docon, 0, ends

/*
        head    210,constant,240,con,docol              ; ***** constant
        .word   creat,smudg,comma,pscod
docon:  mov     (w),-(s)
        next
;
        head    210,variable,240,var,docol              ; ***** variable
        .word   con,pscod
dovar:  mov     w,-(s)
        next
;
        head    207,^/<builds/,323,build,docol          ; ***** <builds
;  create new data type with code routine in higher-level forth.
        .word   zero,con,semis
;
        head    205,does>,276,does,docol                ; ***** does>
        .word   fromr,lates,pfa,store,pscod
dodoe:  mov     ip,-(rp)
        mov     (w)+,ip
        mov     w,-(s)
        next
*/



