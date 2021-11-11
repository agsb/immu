/*********************************************************************

pre-compiled words, for be minimal interactive 

if-else-then with double ends, skips non sense branches to jump

some words from fig-forth pdp-11 "classic"

**********************************************************************/

#---------------------------------------------------------------------- 
# ok  must continue later
# trap for incomplete words
#
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
    .word here, to, cell, allot, ends

#---------------------------------------------------------------------- 
# ok  push a byte onto dictionary
header  "C,", "ccomma",
    .word here, cto, one, allot, ends

#---------------------------------------------------------------------- 
# ok  ( a f -- (a) xor f )
header  "TOGGLE", "toggle",
    .word over, at, xorf, to, ends

#---------------------------------------------------------------------- 
# ok  ( a f - FALSE | TRUE )
header  "FLAGGED", "flagged", 
    .word over, at, andf, zbranch, 2f - .
    .word TRUE, ends
    .word FALSE, ends

#---------------------------------------------------------------------- 
# ok  receive a string from terminal input buffer, always. ( n -- a u )
header  "PARSE-NAME", "parse-name", 
     .word tor,
1:   .word bl_, toin, at, sscan, 
    # test if not empty
     .word dup, zbranch, 2f - .
    # update toin
    .word dup, toin, plusto, 
    # verify length ( a u -- ) (n)
    .word dup, rat, lth, zbranch, 3f - . 
    .word drop, rto, ends 
3:  .word rto, drop, ends
    # else auto refill 
2:  .word tib0, tibz, refill, branch, 1f - .  

#---------------------------------------------------------------------- 
# ok   find
header  "FIND-NAME", "find-name", 
    .word sfind, dup, zbranch, 3f - . 
# ( a1 a3 -- xt -1|1 )
    .word swap, drop, dup, cfa, swap, ffa
    .word docon, F_IMMEDIATE, andf, zbranch, 2f - . 
    .word one, ends
2:  .word oneneg
# ( a1 0 )
3:  .word ends

#---------------------------------------------------------------------- 
# ok  get a string from tib, and search it at dictionary 
#
header "FIND", "find",
    .word parse-name, find-name, ends

#---------------------------------------------------------------------- 
# ok  create a dictionary entry with next word in 'tib', 
# update latest to safe restore DP
#
header "CREATE", "create",
    # leave a address to link
    .word here
    # receive a string
    .word docon, LENGTH, accept
    # place link
    .word latest, at, comma
    # place flags
    .word nil, ccomma
    # place lenght
    .word dup, ccomma
    # place name 
    .word dup, tor, here, swap, cmove, rto, allot 
    # update DP aligned
    .word here, aligned, dp, to
    # update latest
    .word latest, to
    .word ends 
 
#---------------------------------------------------------------------- 
# ok  ends a dictionary entry
# hook for debug
header  "FINITE", "finite", 
    .word ends 

#---------------------------------------------------------------------- 
# ok  ZZZZ
header  "INTERPRET", "interpret", 
    .word evals, ends

#---------------------------------------------------------------------- 
# ok ZZZZ  
header  "ABORT", "abort", 
    .word ends
        
#---------------------------------------------------------------------- 
# ok  tick, returns cfa of next word in input buffer in Top
# not safe for not found word
header  "'", "tick", 
    .word find, drop, ends 

#---------------------------------------------------------------------- 
# ok  as tick, but forces execute next word
header  "'[", "tickexec", F_IMMEDIATE 
    .word tick, execute, ends

#---------------------------------------------------------------------- 
# ok  as tick, but forces compile next word 
header  "']", "tickcomp", F_IMMEDIATE 
    .word tick, comma, ends

#---------------------------------------------------------------------- 
# ok  tick, returns cfa of next word in input buffer in Top
header  "POSTPONE", "postpone", F_IMMEDIATE 
    .word tickcomp, ends

#---------------------------------------------------------------------- 
# ok  evals
header  "EVALS", "evals", 
    .word find, zdup, zbranch, 2f - . 
    .word isword, ends
2:  .word isnumber, ends 

#---------------------------------------------------------------------- 
# ok  
header  "isword", "isword",
# ( xt f  )
    .word state, at 
# ( xt f s )
    .word zbranch, 2f - . 
    .word iscompile, ends
2:  .word doexecute, ends 

#---------------------------------------------------------------------- 
# ok  
header  "iscompile", "iscompile",
# ( xt f ) immediate is 1, else -1
    .word zgth, zbranch, 2f - . 
    .word doexecute, ends
2:  .word docompile, ends

#---------------------------------------------------------------------- 
# ok  compile
# also a hook for debug
header  "docompile", "docompile", 
    .word comma, ends 

#---------------------------------------------------------------------- 
# ok  execute
# also a hook for debug
header  "doexecute", "doexecute", 
    .word execute, ends 

#---------------------------------------------------------------------- 
# ok  
header  "isnumber", "isnumber", 
    .word zzzz, ends

#---------------------------------------------------------------------- 
# ok  to execute
header  "[", "lbrac", 
    .word docon, 0, state, to, ends 
 
#---------------------------------------------------------------------- 
# ok  to compile
header  "]", "rbrac", 
    .word docon, 1, state, to, ends 
#---------------------------------------------------------------------- 
# ok  
header  "COMPILE", "compile", 
    .word docon, comma, ends 
  
#---------------------------------------------------------------------- 
# ok  
header  "CONSTANT", "constant", 
    .word create, compile, docon, comma, finite, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  "VARIABLE", "variable", 
    .word create, compile, dovar, 0, comma, finite, ends 

#---------------------------------------------------------------------- 
# ok  
header  ":", "colon", 
    .word create, rbrac, ends 
 
#---------------------------------------------------------------------- 
# ok  
header  ";", "semmi", 
    .word finite, lbrac, ends 
  
#---------------------------------------------------------------------- 
# ok  ZZZZ
header  "COLD", "cold", 
    .word ends

#---------------------------------------------------------------------- 
# ok  ZZZZ
header  "WARM", "warm", 
    .word ends

#---------------------------------------------------------------------- 
# ok  ZZZZ
header  "BYE", "bye", 
    .word ends

#---------------------------------------------------------------------- 
# ok  ZZZZ
header  "QUIT", "quit", 
    .word ends

/**********************************************************************
    forth control words
**********************************************************************/

#---------------------------------------------------------------------- 
# ok back 
header  "BACK", "back", #f_immediate 
    .word here, swap, minus, comma, ends 
 
#---------------------------------------------------------------------- 
# ok mark 
header  "MARK", "mark", #f_immediate 
    .word here, 0, comma, ends 
 
#---------------------------------------------------------------------- 
# ok begin 
header  "BEGIN", "begin", #f_immediate 
    .word here, ends 
 
#---------------------------------------------------------------------- 
# ok again resolves a backward branch 
header  "AGAIN", "again", #f_immediate 
    .word comp, branch, back, ends 
 
#---------------------------------------------------------------------- 
# ok until 
header  "UNTIL", "until", #f_immediate 
    .word comp, zbranch, back, ends 
 
#---------------------------------------------------------------------- 
# ok unless 
header  "UNLESS", "unless", #f_immediate 
    .word invert, until, ends 
 
#---------------------------------------------------------------------- 
# 
# ok if 
header  "IF", "if", #f_immediate 
    .word comp, zbranch, mark, ends 
 
#---------------------------------------------------------------------- 
# 
# ok endif resolves a forward branch 
header  "ENDIF", "endif", #f_immediate 
    .word dup, here, minus, swap, to, ends 
 
#---------------------------------------------------------------------- 
# 
# ok then 
header  "THEN", "then", #f_immediate 
    .word endif, ends 
 
#---------------------------------------------------------------------- 
# 
# ok else 
header  "ELSE", "else", #f_immediate 
    .word comp, branch, mark, swap, endif, ends 
 
#---------------------------------------------------------------------- 
# 
# ok while 
header  "WHILE", "while", #f_immediate 
    .word if, ends 
 
#---------------------------------------------------------------------- 
# 
# ok repeat 
header  "REPEAT", "repeat", #f_immediate 
    .word tor, tor, again, rat, rat, minus, endif, ends 
 
#---------------------------------------------------------------------- 

#ok hex
header	"HEX", "hex",
	.word docon, 16, base, to, ends

#ok decimal
header	"DECIMAL", "dec",
	.word docon, 10, base, to, ends

#ok hex
header	"OCTAL", "oct",
	.word docon, 8, base, to, ends

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



