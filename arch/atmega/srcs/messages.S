
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

 disclaimer : 
 .ascii  "DISCLAIMER\nthis software is provided \"AS IS\".\n"
 .ascii  "Copyright © 2020, Alvaro Gomes Sobral Barcellos,\n"
 .ascii  "Licence Creative Commons,f8f98284-589e-4290-867c-0ac3824721ac,\n"
 .ascii  "Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)\n"
 .asciiz "please read the disclaimer.\n"
 
 .byte 4
 prompt : ; 4
 .asciz " Ok"
 
 .byte 4
 question : ; 4
 .asciz " ??"
 
 .byte 12
 undefined : ; 12
 .asciz " undefined?"
 
 .byte 12
 exception : ; 12
 .asciz " exception!"
 
 .byte 10
 abort : ; 10
 .asciz " aborted."
 
 roullete: ; 37, Pascal
 ; french: 0-32-15-19-4-21-2-25-17-34-6-27-13-36-11-30-8-23-10-5-24-16-33-1-20-14-31-9-22-18-29-7-28-12-35-3-26
 ; double: 0-28-9-26-30-11-7-20-32-17-5-22-34-15-3-24-36-13-1-00-27-10-25-29-12-8-19-31-18-6-21-33-16-4-23-35-14-2
 ; triple: 0-000-00-32-15-19-4-21-2-25-17-34-6-27-13-36-11-30-8-23-10-5-24-16-33-1-20-14-31-9-22-18-29-7-28-12-35-3-26
 .word  0
 .word 32, 15, 19,  4, 21,  2, 25, 17, 34 
 .word  6, 27, 13, 36, 11, 30,  8, 23, 10
 .word  5, 24, 16, 33,  1, 20, 14, 31,  9
 .word 22, 18, 29,  7, 28, 12, 35,  3, 26

