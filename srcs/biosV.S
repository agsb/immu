//
// minimal BIOS for RISCV GV32
//
// just collecting from sources

/*
( a PDP-11 )
s4 ~X20~ as Rsp, return stack pointer
s5 ~X21~ as Psp, parameter stack pointer
s6 ~X22~ as Ipt, return register for jump and link
s7 ~X23~ as Top, Top on stack
s8 ~X24~ as Nos, Next on stack, pull when need
s9 ~X25~ as Wrk, temporary scratch register
( extras )
s10 ~X26~ as T0, temporary extra
s11 ~X27~ as T1, temporary extra
*/

.macro save-stack
    sw  s4, 0(sp)
    sw  s5, 0(sp)
    sw  s6, 0(sp)
    sw  s7, 0(sp)
    sw  s8, 0(sp)
    sw  s9, 0(sp)
    sw  s10, 0(sp)
    sw  s11, 0(sp)
.endm

.macro load-stack
    lw  s4, 0(sp)
    lw  s5, 0(sp)
    lw  s6, 0(sp)
    lw  s7, 0(sp)
    lw  s8, 0(sp)
    lw  s9, 0(sp)
    lw  s10, 0(sp)
    lw  s11, 0(sp)
.endm

