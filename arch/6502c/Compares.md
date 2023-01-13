# Compare Forth implementations

**This File is a stub**

Traditional Forths for 6502 ISA, uses return stack of 128 words in SP (page one), 
data stack of 64 words in page zero indexed by X register, TOS in A and Y registers.

How it compares with an alternative, using absolute memory $200 and $300
as return and data stacks of 128 cells each, indexed by Y and X, a free A register and using 
four words in page zero as pseudo registers T, N, W, C ?

Comparing, (bytes, cycles operation)

1. Direct access

| bytes | cycles | operation |
| -- | -- | -- |
|classic|
|1, |3,  |pha |
|1, |4,  |pla |
|2, |4,  |sta/lda zp, x |
|2, |4,  |ops zp, x |     
|2, |4,  |sbc/adc zp, x |
|2, |6,  |dec/inc zp, x |

| bytes | cycles | operation |
| -- | -- | -- |
|alternative |
|3, |4,  |sta/lda abs, x/y |
|3, |4,  |ops abs, x |
|3, |4,  |sbc/adc abs, x/y |
|3, |7,  |dec/inc abs, x/y |

As the cycles are about same then the great difference is size of result code, about 1.5 greather
(ops is any of xor, or, and, ror, rol, asl, lsl) 

2. Indirect access

| bytes | cycles | operation |
| -- | -- | -- |
|2, |6  |sta (zp, X) | 
|2, |6  |sta (zp), Y |  

Those are only possible modes to indirect access of a value at memory. Both are used in classics Forths

The alternative must copy the address from memory to zero page, then use it. The copy is done as:
        
        lda abs, x
        sta azp
        lda abs+1, x
        sta azp+1
        
 Incorring in 10 bytes and 16 cycles every indirect access as:
 
        ; using Y
        ; save index
        sty y_save
        ; copy lsb
        ldy #0
        lda (azp), y
        sta abs, x
        ; copy msb
        iny
        lda (azp), y
        sta abs+1, x
        ;load index
        ldy y_save
        
        ; using Y
        sty y_save
        ldy #0
        lda (azp), Y
        sta abs, x
        inc azp
        bne noinc
        inc azp+1
        lda (azp), Y
        sta abs+1, x
        
        
        
