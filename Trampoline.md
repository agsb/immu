# A trampoline table

Most compilers, as gcc, use a trampoline table for fast jump to routines, based on values of a entries onto a mapped relative functions.

The inner interpreter could use same technics but will be slower than direct jumps.

```
 /*
trampoline table of jumps, aka GCC
s4, Psp, parameter stack, grows downwards
s5, Rsp, return stack, grows downwards
s6, Nxt, reference, aka instruction pointer
s7, Top, Top onto parameter stack
s8, Nos, Next temporary, not preserve
s9, Wrk, Work temporary, not preserve
zero, is always zero

this is a trampoline jump table
Wrk could be within 0 to MAX, no safety checks.

in "EXIT", change this 
    _void:
        beq s9, zero, _jump
to this:
    _void:
        addi s8, zero, MAX_OPS
        blt s9, s8, _trampoline
*/

.equ FALSE, 0
.equ TRUE, -1

.macro slook ptr, val, offset
    lw \val, \offset (\ptr)
.endm

.macro spull ptr, val
    lw \val, 0(\ptr)
    addi \ptr, \ptr, -1*CELL
.endm

.macro spush ptr, val
    sw \val, 0(\ptr)
    addi \ptr, \ptr, CELL
.endm

# any order, does not matter, but never change the order later !!!
# functions id's within 1 to MAX_OP, zero is a safe trap to _jump for non inner primitives

.p2align 2
_table:
     .word t_jump
     .word t_zequ
     .word t_zlts
     .word t_to
     .word t_at
     .word t_rsat
     .word t_psat
     .word t_nand
     .word t_plus
     .word t_false
     .word t_true     

.p2align 2     
 _trampoline:
     la Nos, _table
     sll Wrk, Wrk, 2
     add Wrk, Nos, Wrk
     lw  Wrk, 0(Wrk)
     jalr zero, Wrk
     
//----------------------------------------------------------------------
.p2align 2

 t_false:
     addi Top, zero, FALSE
     jal zero, _link
 t_true:
     addi Top, zero, TRUE
     jal zero, _link
t_zequ:
     beq Top, zero, t_true
     jal zero, t_false
t_zlts:
     blt Top, zero, t_true
     jal zero, t_false
t_at:
     lw Top, 0 (Top)
     jal zero, _link
t_to:
     spull Psp, Nos
     sw Top, 0 (Nos)
     jal zero, _link
t_nand:
     spull Psp, Nos
     and Nos, Top, Nos
     neg Top, Nos
     jal zero, _link
t_plus:
     spull Psp, Nos
     add Top, Top, Nos
     jal zero, _link
t_rsat:
     spush Psp, Top
     add Top, Rsp, zero
     jal zero, _link
t_psat:
     spush Psp, Top
     add Top, Psp, zero
     jal zero, _link
     
# and more wold come
```
