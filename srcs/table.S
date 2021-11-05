
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
 */

//----------------------------------------------------------------------

// this is a trampoline jump table
// Wrk could be 0 to MAX, no safe check.

_table:
    jal zero, _trampoline
    .word t_zeru 
    .word t_zequ    
    .word t_to 
    .word t_at 
    .word t_rsat
    .word t_psat
    .word t_nand
    .word t_plus

_trampoline:
    la T0, _table
    sll Wrk, Wrk, 2
    add Wrk, T0, Wrk
    lw  Wrk, 0(Wrk)
    jalr zero, Wrk
 
//----------------------------------------------------------------------
// ( -- 0 )
t_zeru: 
    pspush Top 
    add Top, zero, zero  // li Top, 0
    jal zero, _link

//----------------------------------------------------------------------
// ( w -- FALSE | TRUE)
t_zequ:    
    beq Top, zero, _ftrue
t_false:
    addi Top, zero, FALSE  // li Top, FALSE
    jal zero, _link
t_true:
    addi Top, zero, TRUE   // li Top, TRUE
    jal zero, _link

//----------------------------------------------------------------------
// ( w a -- )
t_to: 
    pspull Nos
    sw Top, 0 (Nos)
    jal zero, _link

//----------------------------------------------------------------------
// ( a -- w )
t_at: 
    lw Top, 0 (Top)
    jal zero, _link

//----------------------------------------------------------------------
// ( -- rsp )
t_rsat:
    pspush Top 
    add Top, zero, Rsp
    jal zero, _link

//----------------------------------------------------------------------
// ( -- psp )
t_psat:
    pspush Top 
    add Top, zero, Psp
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- v nand u )
t_nand:
    pspull Nos
    and Nos, Top, Nos
    neg Top, Nos
    jal zero, _link

//----------------------------------------------------------------------
// ( u v -- v + u )
t_plus:
    pspull Nos
    add Top, Top, Nos
    jal zero, _link

//----------------------------------------------------------------------

