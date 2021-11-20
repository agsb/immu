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
 *  the following conditions"
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *
 *  //-\--/\-//-\/-/\\\\/-\--\\\-///\-/-/\/--/\\\\/-\-//-/\//-/\//--//-///--\\\-///\-/-/\/
 *
 *  licensed with GPL 2.0
 *
 */

/*********************************************************************

pre-compiled words, for be minimal interactive 

if-else-then with double ends, skips non sense branches to jump

0 is called nil, because zero is reserved for the x0 riscv register

some words from fig-forth, pdp-11, 1980, "classic"

no complex listings

**********************************************************************/

//---------------------------------------------------------------------- 
// ok  must continue later
// trap for incomplete words caused by unsleeped nights
//
header  "ZZZZ", "zzzz", 
    .word ends 

//---------------------------------------------------------------------- 
// ok STATE
header "STATE", "state"
    .word dolit, STATE, ends
    
//---------------------------------------------------------------------- 
// ok BASE
header "BASE", "base"
    .word dolit, BASE, ends
    
//---------------------------------------------------------------------- 
// ok LATEST
header "LATEST", "latest"
    .word dolit, LATEST, ends
    
//---------------------------------------------------------------------- 
// ok TOIN
header ">IN", "toin"
    .word dolit, TOIN, ends
    
//---------------------------------------------------------------------- 
// ok DP
header "DP", "dp"
    .word dolit, FREEF, ends
    
//---------------------------------------------------------------------- 
// ok UP
header "UP", "up"
    .word dolit, FRAMF, ends

//---------------------------------------------------------------------- 
// ok CONTEXT
header "CONTEXT", "context"
    .word dolit, CONTXT, ends

//---------------------------------------------------------------------- 
// ok CURRENT
header "CURRENT", "current"
    .word dolit, CURTXT, ends
            
//---------------------------------------------------------------------- 
// ok  DEFINITIONS
header  "DEFINITIONS", "definitions",
    .word context, at, current, to, ends

//---------------------------------------------------------------------- 
// ok  SOURCE
header  "SOURCE", "source",
    .word dolit, XTIB, dolit, BUFFER, ends

//---------------------------------------------------------------------- 
// ok  must continue later
header  "ALLOT", "allot",
    .word dp, plusto, ends
    
//---------------------------------------------------------------------- 
// ok  must continue later
header  "HERE", "here",
    .word dp, at, ends

//---------------------------------------------------------------------- 
// ok  push a cell onto dictionary
header  ",", "comma",
    .word here, to, cell, allot, ends

//---------------------------------------------------------------------- 
// ok  push a byte onto dictionary
header  "C,", "ccomma",
    .word here, cto, one, allot, ends

//---------------------------------------------------------------------- 
// ok  ( a f -- (a) xor f )
header  "TOGGLE", "toggle",
    .word over, at, xorf, to, ends

//---------------------------------------------------------------------- 
// ok  ( a f - FALSE | TRUE )
header  "FLAGGED", "flagged", 
    .word over, at, andf, zbranch, 2f - .
    .word TRUE, ends
2:  .word FALSE, ends

/***********************************************************************
    still no assembler
***********************************************************************/
//---------------------------------------------------------------------- 
//   
header  "CODE", "code",
    .word zzzz, ends

//---------------------------------------------------------------------- 
//   
header  "END-CODE", "endcode",
    .word zzzz, ends

//---------------------------------------------------------------------- 
//   
header  ";CODE", "semicode",
    .word zzzz, ends

//---------------------------------------------------------------------- 
//   
header  ".\"", "dotquote",
    .word zzzz, ends

//---------------------------------------------------------------------- 
//   
header  ".(", "dotparen",
    .word zzzz, ends

//----------------------------------------------------------------------
//   
header "CHAR", "char"
    .word zzzz, ends
//----------------------------------------------------------------------
//  parse, as forth 94 std  "sssss<c>"  (c c-addr -- c-addr n )
// 
header "PARSE", "parse"
2:  //
    .word over, over
    .word at, dup, zbranch, 6f - .
    .word equ, zbranch, 4f - .
    .word one, plus, branch, 2b
4:  // zzzzzz
6:  // zero 
    .word drop, drop, drop, drop, nil, ends

//----------------------------------------------------------------------
//  accept, as forth 94 std ( a n -- )
// 
head
er "accept", "accept"
    .word source, refill, nil, toin, to, ends

//----------------------------------------------------------------------
//  refill, as forth 94 std ( a n -- )
// always receive from key
// always place a space at start, to serve as placeholder of length of a word
// always place a nil at end, to mark end of buffer
// no edit capable
header "refill", "refill"
    // append a space at start, and advance to next
    .word over, bl, swap, to
    // keep lenght, start counter at zero
    .word rto, nil
1:   // last in ?
    .word dup, rat, zgth, zbranch, 20f -.
2:  // getch, blocks while

ZZZZ

    .word key
    // verify  
    // normal end of line
    .word dup, dolit, CR_, minus, zbranch, 18f - .
    .word dup, dolit, LF_, minus, zbranch, 18f - .
    // unexpected end of file
    .word dup, dolit, EOF_, minus, zbranch, 18f - .
    // unexpected cancel
    .word dup, dolit, CAN_, minus, zbranch, 16f - .
    // do ESC
    .word dup, dolit, ESC_, minus, zbranch, 14f - .
    // minimal edits
    .word dup, dolit, BS_, minus, zbranch, 10f -.
    .word dup, dolit, TB_, minus, zbranch, 8f - .
    // accept valid characters
    .word dup, dolit, BL_ - 1, gth, zbranch, 12f - .
    .word dup, dolit, TL_ + 1, lth, zbranch, 12f - .
4:   // check if space
    .word dup, dolit, BL_, equ, zbranch, 6f - .
    .word   
6:   // do valid
    .word tor, over, over, plus, rto, swap, to
    .word one, plus
    .word branch, 1b - .
8:  // do tab 
    .word drop, dolit, BL_
    .word branch, 4b - .
10:  // do backspace
    .word drop
    .word dup, zgth, zbranch, 2b - .
    .word one, minus
    .word branch, 2b - .
12: // no valid
14: // ESC
16: // CAN
    .word drop
    .word branch, 2b - .
18: // cr-lf ( a n c)
    .word drop
20: // append a null ( a n )
    .word drop, nil, swap, to
    .word rto, drop
    .word ends

//----------------------------------------------------------------------
//
header "WORD", "word"
    // see buffer
    .word dolit, XTIB, dolit, TOIN, 
    .word dup, dolit, BUFFER, lessth, 4f - .
    .word zzzz
    .word ends


//----------------------------------------------------------------------
//
header "QUERY", "query"
    .word dolit, XTIB, dolit, BUFFER, accept, 0, toin, to, ends

//---------------------------------------------------------------------- 
//   receive a string from terminal input buffer, always. ( n -- a u )
header  "PARSE-NAME", "parsename", 
     .word tor
1:   .word dolit, BL_, toin, at, sscan 
    // test if not empty
     .word dup, zbranch, 2f - .
    // update toin
    .word dup, toin, plusto 
    // verify length ( a u -- ) (n)
    .word dup, rat, lth, zbranch, 3f - . 
    .word drop, rto, ends 
3:  .word rto, drop, ends
    // else auto refill 
2:  .word zzzz, refill, branch, 1b - .  

//---------------------------------------------------------------------- 
//    find
header  "FIND-NAME", "findname", 
    .word sfind, dup, zbranch, 3f - . 
// ( a1 a3 -- xt -1|1 )
    .word swap, drop, dup, cfa, swap, ffa
    .word dolit, F_IMMEDIATE, andf, zbranch, 2f - . 
    .word one, ends
2:  .word oneneg
// ( a1 0 )
3:  .word ends

//---------------------------------------------------------------------- 
//   get a string from tib, and search it at dictionary 
//
header "FIND", "find",
    .word parsename, findname, ends

//---------------------------------------------------------------------- 
//   create a dictionary entry with next word in 'tib', 
// update latest to safe restore DP
//
header "CREATE", "create",
    // leave a address to link
    .word here
    // receive a string
    .word accept
    // place link
    .word latest, at, comma
    // place flags
    .word nil, ccomma
    // place length 
    .word dup, ccomma
    // place name 
    .word dup, tor, here, swap, cmove, rto, allot 
    // update DP aligned
    .word here, aligned, dp, to
    // update latest
    .word latest, to
    .word ends 
 
//---------------------------------------------------------------------- 
//   ends a dictionary entry
// hook for debug
header  "FINITE", "finite", 
    .word ends 

//---------------------------------------------------------------------- 
//   ZZZZ
header  "INTERPRET", "interpret", 
    .word evaluate, ends

//---------------------------------------------------------------------- 
//  ZZZZ  
header  "ABORT", "abort", 
    .word dolit, XRSP, rsto
    .word dolit, XPSP, psto
    .word dolit, XTIB, dolit, TIBF, to
    .word ends
        
//---------------------------------------------------------------------- 
//   tick, returns cfa of next word in input buffer in Top
// not safe for not found word
header  "'", "tick", 
    .word find, drop, ends 

//---------------------------------------------------------------------- 
//   as tick, but forces execute next word
header  "'[", "tickexec", F_IMMEDIATE 
    .word tick, exec, ends

//---------------------------------------------------------------------- 
//   as tick, but forces compile next word 
header  "']", "tickcomp", F_IMMEDIATE 
    .word tick, comma, ends

//---------------------------------------------------------------------- 
//   tick, returns cfa of next word in input buffer in Top, zzzz still
header  "POSTPONE", "postpone", F_IMMEDIATE 
    .word tickcomp, ends

//---------------------------------------------------------------------- 
//   compile
// also a hook for debug
header  "docompile", "docompile", 
    .word comma, ends 

//---------------------------------------------------------------------- 
//   execute
// also a hook for debug
header  "doexecute", "doexecute", 
    .word exec, ends 

//---------------------------------------------------------------------- 
//   
header  "iscompile", "iscompile",
// ( xt f ) immediate is 1, else -1
    .word zgth, zbranch, 2f - . 
    .word doexecute, ends
2:  .word docompile, ends

//---------------------------------------------------------------------- 
//   
header  "isword", "isword",
// ( xt f  )
    .word state, at 
// ( xt f s )
    .word zbranch, 2f - . 
    .word iscompile, ends
2:  .word doexecute, ends 

//---------------------------------------------------------------------- 
//   
header  "isnumber", "isnumber", 
    .word zzzz, ends

//---------------------------------------------------------------------- 
//   evals
header  "EVALUATE", "evaluate", 
    .word find, zdup, zbranch, 2f - . 
    .word isword, ends
2:  .word isnumber, ends 

//---------------------------------------------------------------------- 
// ok  to execute
header  "[", "lbrac", 
    .word dolit, 0, state, to, ends 
 
//---------------------------------------------------------------------- 
// ok  to compile
header  "]", "rbrac", 
    .word dolit, 1, state, to, ends 

//---------------------------------------------------------------------- 
// ok  comp, classic
header  "COMPILE,", "comp", 
    .word rto, dup, at, comma, cell, plus, tor, ends 

//----------------------------------------------------------------------
// ok  exec, a Top reference is pushed into return stack
header "EXECUTE", "exec", 
    .word tor, ends

//----------------------------------------------------------------------
//   dodoes (?), interpreter continues at contents of cell
header "DODOES", "dodoes", 
    .word rto, at, tor, ends
    
//---------------------------------------------------------------------- 
//   ( w -- )
header  "CONSTANT", "constant", F_IMMEDIATE
    .word create, comp, dolit, comma, finite, ends 
 
//---------------------------------------------------------------------- 
//   ( -- )
header  "VARIABLE", "variable", F_IMMEDIATE
    .word create, comp, dolit, 0, comma, finite, ends 

//---------------------------------------------------------------------- 
//   
header  "SMUDGED", "smudged", 
    .word latest, at, cell, plus, dolit, F_HIDDEN, toggle, ends

//---------------------------------------------------------------------- 
//   
header  "IMMEDIATE", "immediate", 
    .word latest, at, cell, plus, dolit, F_IMMEDIATE, toggle, ends

//---------------------------------------------------------------------- 
//   
header  "COMPILE_ONLY", "compileonly", 
    .word latest, at, cell, plus, dolit, F_COMPILE_ONLY, toggle, ends

//---------------------------------------------------------------------- 
//   
header  ":", "colon", 
    .word create, smudged, rbrac, ends 
 
//---------------------------------------------------------------------- 
//   
header  ";", "semmi", 
    .word finite, comp, ends, smudged, lbrac, ends 
  

//---------------------------------------------------------------------- 
// ok  ( -- )
header  "SPACE", "space", 
    .word dolit, BL_, emit, ends

//---------------------------------------------------------------------- 
// ok  ( n -- )
header  "SPACES", "spaces", 
1:  .word dup, zbranch, 2f -.
    .word space, one, minus
    .word branch, 1b - .
2:  .word drop, ends

//---------------------------------------------------------------------- 
// ok  (a n -- )
header  "TYPE", "type", 
1:  .word dup, zbranch, 2f -.
    .word swap, dup, at, emit 
    .word one, plus, swap
    .word one, minus
    .word branch, 1b - .
2:  .word drop, ends

//---------------------------------------------------------------------- 
//   (a n -- )
header  "VOCABULARY", "vocabulary",
    .word zzzz, ends


//---------------------------------------------------------------------- 
// ok exit, exits immediately :)
header  "EXIT", "exit",  F_IMMEDIATE 
    .word comp, ends, ends

/**********************************************************************
    forth control words, as in forth-79

    added FOR, a index 0 do
**********************************************************************/

//---------------------------------------------------------------------- 
// ok back, resolves a backward branch
header  "BACK", "back",  F_IMMEDIATE 
    .word here, swap, minus, comma, ends 
 
//---------------------------------------------------------------------- 
// ok mark, marks for a branch 
header  "MARK", "mark",  F_IMMEDIATE 
    .word here, nil, comma, ends 
 
//---------------------------------------------------------------------- 
// ok begin 
header  "BEGIN", "begin",  F_IMMEDIATE 
    .word here, ends 
 
//---------------------------------------------------------------------- 
// ok again resolves a backward branch 
header  "AGAIN", "again",  F_IMMEDIATE 
    .word comp, branch, back, ends 
 
//---------------------------------------------------------------------- 
// ok until 
header  "UNTIL", "until",  F_IMMEDIATE 
    .word comp, zbranch, back, ends 
 
//---------------------------------------------------------------------- 
// ok end 
header  "END", "end",  F_IMMEDIATE 
    .word until, ends 
 
//---------------------------------------------------------------------- 
// ok unless 
header  "UNLESS", "unless",  F_IMMEDIATE 
    .word invert, until, ends 
 
//---------------------------------------------------------------------- 
// 
// ok if 
header  "IF", "if", F_IMMEDIATE
    .word comp, zbranch, mark, ends 
 
//---------------------------------------------------------------------- 
// 
// ok endif resolves a forward branch 
header  "ENDIF", "endif",  F_IMMEDIATE 
    .word dup, here, minus, swap, to, ends 
 
//---------------------------------------------------------------------- 
// 
// ok then 
header  "THEN", "then",  F_IMMEDIATE 
    .word endif, ends 
 
//---------------------------------------------------------------------- 
// 
// ok else 
header  "ELSE", "else",  F_IMMEDIATE 
    .word comp, branch, mark, swap, endif, ends 
 
//---------------------------------------------------------------------- 
// 
// ok while 
header  "WHILE", "while",  F_IMMEDIATE 
    .word if, ends 
 
//---------------------------------------------------------------------- 
// 
// ok repeat 
header  "REPEAT", "repeat",  F_IMMEDIATE 
    .word again, minus, endif, ends 
 
//---------------------------------------------------------------------- 
// S:( index limit -- ) R:( -- limit index)
// as continue from C, forth-94 as ?REPEAT
header  "CONTINUE", "continue", F_IMMEDIATE 
    .word dup, again, ends 

//---------------------------------------------------------------------- 
// ok 
header	"chain,", "chaincomma",
	.word dup, at, comma, to, ends

//---------------------------------------------------------------------- 
// ok 
// solve leave chain
header	"chain&", "chainamper",
  	.word at, 
1:  .word zdup, zbranch, 2f - .
    .word dup, at, here, rot, to
    .word branch, 1b - .
2:  .word ends

//---------------------------------------------------------------------- 
// ok 
header	"new_leaves", "new_leaves",
   // save old leave onto stack
    .word dolit, LEAV, at, 
    // init a new leave chain
    .word nil, dolit, LEAV, to
    .word ends

//---------------------------------------------------------------------- 
// ok 
header	"old_leaves", "old_leaves",
    // resolve leaves chain
    .word dolit, LEAV, chain&    
    // load old leave from stack 
    .word dolit, LEAV, to, ends
    .word ends
 
//---------------------------------------------------------------------- 
// as break from C, chain forward references 
header	"LEAVE", "leave",
	.word comp, branch, here, dolit, LEAV, chaincomma, ends

//---------------------------------------------------------------------- 
// S:( limit -- ) R:( -- limit 0)
// for -- loop  
header  "FOR", "for", 
    .word xfor, here, ends 

//---------------------------------------------------------------------- 
// S:( limit index -- ) R:( -- index limit )
// do -- loop
header  "DO", "do", F_COMPILE_ONLY
    // save old leave onto stack
    .word new_leaves
    // place limit and index on return stack, and go on
    .word tor, tor, here, nil, ends 

//---------------------------------------------------------------------- 
// increase index by one, loop while index less than limit
// loop
header  "LOOP", "oneloop",  F_COMPILE_ONLY 
    .word one, loop, ends
 
//---------------------------------------------------------------------- 
// drop index and limit
// unloop
header  "UNLOOP", "unloop",  F_COMPILE_ONLY 
    .word rto, drop, rto, drop
    .word old_leaves, ends
    
//---------------------------------------------------------------------- 
// increase index by Top, loop while index less than limit
// loopplus
header  "+LOOP", "loop",  F_COMPILE_ONLY
    .word rto, swap, rto, plus    // (limit incr+index)
    .word over, over, gth, zbranch, 2f - .
    .word tor, tor, again
2: 
    .word unloop
    .word ends    
    
//---------------------------------------------------------------------- 
// ok hex
header	"HEX", "hex",
	.word dolit, 16, base, to, ends

// ok decimal
header	"DECIMAL", "dec",
	.word dolit, 10, base, to, ends

// ok hex
header	"OCTAL", "oct",
	.word dolit, 8, base, to, ends

//---------------------------------------------------------------------- 

//  <builds
header	"<BUILDS", "builds"
	.word zzzz, ends

//  does> 
header	"DOES>", "does"
	.word zzzz, ends

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

/*
...                                                 ( c-addr )
FIND ?DUP IF	                                    ( xt +-1 )
   STATE @ IF	                                    ( xt +-1 )
     0> IF EXECUTE ELSE COMPILE, THEN	            ( ??? )
   ELSE	                                            ( xt +-1 )
     DROP EXECUTE                                   ( ??? )
   THEN
ELSE                                                ( c-addr )
   ( whatever you do for an undefined word )
THEN
... 

*/



//---------------------------------------------------------------------- 
// ok HANDLER \last exception handler, forth-94
header	"HANDLER", "handler"
    .word dovar, nil, ends

//---------------------------------------------------------------------- 
// ok CATCH (xt -- exception | 0), forth-94
header	"CATCH", "catch"
    .word psat, tor, handler, at, tor, rsat, handler, to, exec
    .word rto, handler, to, rto, handler, to, rto, drop, dolit, nil, ends

//---------------------------------------------------------------------- 
// ok THROW (exception -- exception | 0), forth-94
header	"THROW", "throw"
   .word zdup, zbranch, 2f - . 
   .word handler, at, rsto, rto, handler, to 
   .word rto, swap, tor, psto, drop, rto 
2: .word ends

//---------------------------------------------------------------------- 
// ok PICK (A -- N)
header	"PICK", "pick"
	.word cells, psat, plus, at, ends

//---------------------------------------------------------------------- 
// ok 2DROP (A B -- )
header	"2DROP", "twodrop"
	.word drop, drop, ends

//---------------------------------------------------------------------- 
// ok 2DUP (A B -- A B A B)
header	"2DUP", "twodup"
	.word over, over, ends

//---------------------------------------------------------------------- 
// ok 2SWAP (A B C D -- C D A B)
header	"2SWAP", "twoswap"
	.word rot, tor, rot, rto, ends

//---------------------------------------------------------------------- 
// ok 2OVER (A B C D -- A B C D A B)
header	"2OVER", "twoover"
	.word zzzz, ends

//---------------------------------------------------------------------- 
// ok 2TO (w1 w2 a -- )
header	"2!", "twoto"
	.word swap, to, cellplus, to, ends

//---------------------------------------------------------------------- 
// ok 2AT (a -- w1 w2 a)
header	"2@", "twoat"
	.word dup, cellplus, at, swap, at, ends  

//---------------------------------------------------------------------- 
// ok 2>R (S:w1 w2 -- ) (R: -- w1 w2)
header	"2>R", "twotor"
	.word swap, tor, tor, ends  

//---------------------------------------------------------------------- 
// ok 2R> (S: -- w1 w2) (R: w1 w2 --)
header	"2R>", "tworto"
	.word rto, rto, swap, ends  

//---------------------------------------------------------------------- 
// ok 2R@ (S: -- w1 w2) (R: -- w1 w2)
header	"2R@", "tworat"
	.word rto, rto, twodup, tor, tor, swap, ends  

//---------------------------------------------------------------------- 
//   ZZZZ
header  "COLD", "cold", 
    .word ends

//---------------------------------------------------------------------- 
//   ZZZZ
header  "WARM", "warm", 
    .word ends

//---------------------------------------------------------------------- 
//   ZZZZ
header  "BYE", "bye", 
    .word ends

//---------------------------------------------------------------------- 
//   
header  "QUIT", "quit", 
    .word dolit, XRSP, rsto, lbrac, ends


