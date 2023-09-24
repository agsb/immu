
/*
 *  DISCLAIMER
 *
 *  Copyright © 2021, Alvaro Gomes Sobral Barcellos,
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

/*
A Forth with minimal indirect thread code

(S: w1 w2 w3 -- w1 w3) parameter stack, before -- after, w3 at top
(R: w1 w2 w3 -- w1 w3) return stack, before -- after, w3 at top

simetric division, floored to zero

// RISCV considerations 

Using R32IM, 32 bits cell, 

must be saved by subroutines (calee)

( a PDP-11 )
s4 ~X20~ as Rsp, return stack pointer
s5 ~X21~ as Psp, parameter stack pointer
s6 ~X22~ as Lnk, Link pointer, reserved  
s7 ~X23~ as Top, Top on stack, reserved
s8 ~X24~ as Nos, Next on stack, when need
s9 ~X25~ as Wrk, temporary scratch register

( extras )
s10 ~X26~ as T0, temporary extra
s11 ~X27~ as T1, temporary extra

Why T0 and T1 ? 

To make easy memmov, memcpy.
A mem needs five registers 
two for address sources, two for contents bytes, 
and maybe a counter.
else many stack operations are need

```
*/

//----------------------------------------------------------------------
