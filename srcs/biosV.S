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

# adapted from https://github.com/theandrew168/derzforth/tree/main/boards/longan_nano
# include definitions related to the GigaDevice GD32VF103 family of chips
# (the --include-definitions flag to bronzebeard puts this on the path)

# ps. not safe for interrupts

include GD32VF103.inc

# 32KB @ 0x20000000
RAM_BASE_ADDR = 0x20000000
RAM_SIZE = 32 * 1024

# 128KB @ 0x08000000
ROM_BASE_ADDR = 0x08000000
ROM_SIZE = 128 * 1024

# 8MHz is the default GD32VF103 clock freq
CLOCK_FREQ = 8000000


# Func: gpio_config
# Arg: Top = GPIO port base addr
# Arg: Nos = GPIO pin number
# Arg: Wrk = GPIO config (4 bits)
header "gpio_config", "gpio_config_do"
    spull Psp, Nos

gpio_config:
    # advance to CTL0
    addi Top, Top, GPIO_CTL0_OFFSET

    # if pin number is less than 8, CTL0 is correct
    slti t1, Nos, 8
    bnez t1, gpio_config_store

    # else we need CTL1 and 
    addi Top, Top, 4
	# then subtract 8 from the pin number
    addi Nos, Nos, -8

gpio_config_store:
    # multiply pin number by 4 to get shift amount
    slli Nos, Nos, 2

    # load current config
    lw t1, 0(Top)

    # align and clear existing pin config
    li Wrk, 0b1111
    sll Wrk, Wrk, Nos
    not Wrk, Wrk
    and t1, t1, Wrk
#zzzz
    spull Psp, Wrk
    # align and apply new pin config
    sll Wrk, Wrk, Nos
    or t1, t1, Wrk

    # store updated config
    sw t1, 0(Top)

gpio_config_done:
	spull Psp, Top
	jal zero, _link
    


# Func: serial_init
# Arg: Top = baud rate
header "serial_init", "serial_init_do"
serial_init:
    # save return addr (since serial_init calls other funcs)
    mv s8, ra

    # setup RCU base addr in Nos
    li Nos, RCU_BASE_ADDR

    # enable RCU (USARNos, GPIOA, and AFIO)
    li Wrk, RCU_APB2EN_USARNosEN | RCU_APB2EN_PAEN | RCU_APB2EN_AFEN
    sw Wrk, RCU_APB2EN_OFFSET(Nos)

    # setup USARNos base addr in Nos
    li Nos, USART_BASE_ADDR_0

    # calculate and store clkdiv (CLKDIV = CLOCK // BAUD)
    li Wrk, CLOCK_FREQ
    div Wrk, Wrk, Top
    sw Wrk, USART_BAUD_OFFSET(Nos)

    # enable USART (USART, TX, and RX)
    li Wrk, USART_CTL0_UEN | USART_CTL0_TEN | USART_CTL0_REN
    sw Wrk, USART_CTL0_OFFSET(Nos)

#zzzz
    # configure TX pin
    li Top, GPIO_BASE_ADDR_A
    li Nos, 9
    li Wrk, GPIO_CONFIG_AF_PP_50MHZ
    call gpio_config

#zzzz
    # configure RX pin
    li Top, GPIO_BASE_ADDR_A
    li Nos, 10
    li Wrk, GPIO_CONFIG_IN_FLOAT
    call gpio_config

serial_init_done:
    # restore return addr and return
    mv ra, s8
    ret


# Func: serial_getc
# Ret: Top = character received
header "serial_getc", "serial_getc_do"
    spush Psp, Tos
serial_getc:
    li Nos, USART_BASE_ADDR_0		# load USART base addr into Nos
serial_getc_loop:
    lw Wrk, USART_STAT_OFFSET(Nos)  # load status into Wrk
    andi Wrk, Wrk, USART_STAT_RBNE  # isolate read buffer not empty (RBNE) bit
    beqz Wrk, serial_getc_loop		# keep looping until ready to recv
    lw Top, USART_DATA_OFFSET(Nos)	# load char into Top
    andi Top, Top, 0xff				# isolate bottom 8 bits
serial_getc_done:
    jal zero, _link	

# Func: serial_putc
# Arg: Top = character to send
header "serial_putc", "serial_putc_do"
serial_putc:
    li Nos, USART_BASE_ADDR_0		# load USART base addr into Nos
serial_putc_loop:
    lw Wrk, USART_STAT_OFFSET(Nos)  # load status into Wrk
    andi Wrk, Wrk, USART_STAT_TBE   # isolate transmit buffer empty (TBE) bit
    beqz Wrk, serial_putc_loop		# keep looping until ready to send
    andi Top, Top, 0xff				# isolate bottom 8 bits
    sw Top, USART_DATA_OFFSET(Nos)	# write char from Top
serial_putc_done:
	spull Psp, Top
    jal zero, _link	
    
    
