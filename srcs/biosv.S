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

//
// adapted from:
// https://github.com/riscv-mcu/GD32VF103_Firmware_Library/blob/master/Firmware/RISCV/env_Eclipse/entry.S
//

//---------------------------------------------------------------------
// Disable Interrupt
//
.macro DISABLE_MIE
  csrc CSR_MSTATUS, MSTATUS_MIE  
.endm


//---------------------------------------------------------------------
// push used registers
// leave one extra cell at top, 
.macro pushs_onto_stack
	addi sp, sp, -12*CELL
    sw  s4, 1*CELL(sp)
    sw  s5, 2*CELL(sp)
    sw  s6, 3*CELL(sp)
    sw  s7, 4*CELL(sp)
    sw  s8, 5*CELL(sp)
    sw  s9, 6*CELL(sp)
    sw  s10, 7*CELL(sp)
    sw  s11, 8*CELL(sp)
.endm

//---------------------------------------------------------------------
// pull used registers
// leave one extra cell at top, 
.macro pulls_from_stack
    lw  s4, 1*CELL(sp)
    lw  s5, 2*CELL(sp)
    lw  s6, 3*CELL(sp)
    lw  s7, 4*CELL(sp)
    lw  s8, 5*CELL(sp)
    lw  s9, 6*CELL(sp)
    lw  s10, 7*CELL(sp)
    lw  s11, 8*CELL(sp)
	addi sp, sp, +12*CELL
.endm

//---------------------------------------------------------------------
// push extra registers
.macro pushs_epc_status
	csrr s11, CRS_MEPC
    sw  s11, 9*CELL(sp)
	csrr s11, CRS_MSTATUS
    sw  s11, 10*CELL(sp)
	csrr s11, CRS_MSUBM
    sw  s11, 11*CELL(sp)
.endm

//---------------------------------------------------------------------
// pull extra registers
.macro pulls_epc_status
    lw  s11, 9*CELL(sp)
	csrr s11, CRS_MEPC
    lw  s11, 10*CELL(sp)
	csrr s11, CRS_MSTATUS
    lw  s11, 11*CELL(sp)
	csrr s11, CRS_MSUBM
.endm


//---------------------------------------------------------------------
	// adapted from https://github.com/theandrew168/derzforth/tree/main/boards/longan_nano
	// include definitions related to the GigaDevice GD32VF103 family of chips
	// (the --include-definitions flag to bronzebeard puts this on the path)

	// ps. not safe for interrupts

#include "GD32VF103.asm"

// 128KB @ 0x08000000
ROM_BASE_ADDR = 0x08000000
ROM_SIZE = 128 * 1024

// 32KB @ 0x20000000
RAM_BASE_ADDR = 0x20000000
RAM_SIZE = 32 * 1024

// 8MHz is the default GD32VF103 clock freq
CLOCK_FREQ = 8000000


//---------------------------------------------------------------------
// void gpio_init(uint32_t gpio_periph, uint32_t mode, uint32_t speed, uint32_t pin)
// ( gpio_periph mode speed pin )
//---------------------------------------------------------------------

//---------------------------------------------------------------------
// Func: gpio_config
// Arg: Top = GPIO port base addr
// Arg: Nos = GPIO pin number
// Arg: Wrk = GPIO config (4 bits)
header "gpio_config_pin", "gpio_config_pin_do"
	// save Top
	spush Psp, Top

	// in order at stack: 
	// ( 'config 4 bits' 'pin number' 'port base addr' -- )  
    lw Nos, CELL (Psp)

gpio_config:
    // advance to CTL0
    addi Top, Top, GPIO_CTL0_OFFSET

    // if pin number is less than 8, CTL0 is correct
    slti Wrk, Nos, 8
    bnez Wrk, gpio_config_store

    // else we need CTL1 and 
    addi Top, Top, 4
	// then subtract 8 from the pin number
    addi Nos, Nos, -8

gpio_config_store:
    // multiply pin number by 4 to get shift amount
    slli Nos, Nos, 2

    // load current config
    lw Wrk, 0(Top)

    // save new address
	sw Top, 0 (Psp)

    // align and clear existing pin config
    li Top, 0b1111
    sll Top, Top, Nos
    not Top, Top
    and Wrk, Wrk, Top
    
	// load GPIO config
	lw Top, CELL*2 (Psp)
    // align and apply new pin config
    sll Top, Top, Nos
    or Wrk, Wrk, Top

	// load address
	lw Top, 0(Psp)
    // store updated config
    sw Wrk, 0(Top)

gpio_config_done:
	// drop parameters
	add Psp, Psp, CELL * 3
	// update Top
	spull Psp, Top
	jal zero, _link

//---------------------------------------------------------------------
//gpio_init(GPIOA, GPIO_MODE_IN_FLOATING, GPIO_OSPEED_50MHZ, GPIO_PIN_10);
// configure TX pin
header "configure_tx_pin", "configure_default_tx_pin_do"
	.word dup, zbranch, 2f - .
	.word dolit, GPIO_CONFIG_AF_PP_50MHZ
	.word dolit, 9
    .word dolit, GPIO_BASE_ADDR_A
	.word gpio_config_pin_do
    .word ends

//---------------------------------------------------------------------
// configure RX pin
header "configure_rx_pin", "configure_rx_pin_do"
	.word dolit, GPIO_CONFIG_IN_FLOAT
	.word dolit, 10
    .word dolit, GPIO_BASE_ADDR_A
	.word gpio_config_pin_do
    .word ends

//	from: https://github.com/riscv-mcu/GD32VF103_Firmware_Library/
//	blob/master/Firmware/GD32VF103_standard_peripheral/Source/gd32vf103_usart.c

//---------------------------------------------------------------------
// Func: serial_init
// Arg: Top = baud rate
//       reset USART0 
//        rcu_periph_reset_enable(RCU_USART0RST);
//        rcu_periph_reset_disable(RCU_USART0RST);
//        break;
    
header "serial_init", "serial_init_do"
serial_init:

    // setup RCU base addr in Nos
    li Nos, RCU_BASE_ADDR

    // enable RCU (USARNos, GPIOA, and AFIO)
    li Wrk, RCU_APB2EN_USART0EN | RCU_APB2EN_PAEN | RCU_APB2EN_AFEN
    sw Wrk, RCU_APB2EN_OFFSET(Nos)

    // setup USARNos base addr in Nos
    li Nos, USART_BASE_ADDR_0

    // calculate and store clkdiv (CLKDIV = CLOCK // BAUD)
    li Wrk, CLOCK_FREQ
    div Wrk, Wrk, Top
    sw Wrk, USART_BAUD_OFFSET(Nos)

    // enable USART (USART, TX, and RX)
    li Wrk, USART_CTL0_UEN | USART_CTL0_TEN | USART_CTL0_REN
    sw Wrk, USART_CTL0_OFFSET(Nos)
	
	// moved configure_TX:
	// moved configure_RX:

serial_init_done:
    // restore Top
	spull Psp, Top
    Jal zero, _link
		
//---------------------------------------------------------------------
// Func: serial_config
// default at boot is 8-N-1 fixed
// USART_WL_8BIT: 8 bits
// USART_PM_NONE: no parity
// USART_STB_1BIT:   1 bit
//
// todo: (stop_bit_length parity_flag bits_length -- )
header "serial_config", "serial_config_do"
serial_parity_done:
	jal zero, _link
/*
	
    // clear USART_CTL0 WL bit 
    USART_CTL0(usart_periph) &= ~USART_CTL0_WL;
    // configure USART word length
    USART_CTL0(usart_periph) |= USART_WL_8BIT;
    // clear USART_CTL0 PM,PCEN bits 
    USART_CTL0(usart_periph) &= ~(USART_CTL0_PM | USART_CTL0_PCEN);
    // configure USART parity mode 
    USART_CTL0(usart_periph) |= USART_PM_NONE;
    // clear USART_CTL1 STB bits 
    USART_CTL1(usart_periph) &= ~USART_CTL1_STB; 
    // configure USART stop bits 
    USART_CTL1(usart_periph) |= USART_STB_1BIT;
*/

//---------------------------------------------------------------------
// Func: serial_getc
// Ret: Top = character received
header "serial_getc", "serial_getc_do"
    spush Psp, Top
serial_getc:
    li Nos, USART_BASE_ADDR_0		// load USART base addr into Nos
serial_getc_loop:
    lw Wrk, USART_STAT_OFFSET(Nos)  // load status into Wrk
    andi Wrk, Wrk, USART_STAT_RBNE  // isolate read buffer not empty (RBNE) bit
    beqz Wrk, serial_getc_loop		// keep looping until ready to recv
serial_getc_it:
    lw Top, USART_DATA_OFFSET(Nos)	// load char into Top
    andi Top, Top, 0xff				// isolate bottom 8 bits
serial_getc_done:
    jal zero, _link	

//---------------------------------------------------------------------
// Func: serial_putc
// Arg: Top = character to send
header "serial_putc", "serial_putc_do"
serial_putc:
    li Nos, USART_BASE_ADDR_0		// load USART base addr into Nos
serial_putc_loop:
    lw Wrk, USART_STAT_OFFSET(Nos)  // load status into Wrk
    andi Wrk, Wrk, USART_STAT_TBE   // isolate transmit buffer empty (TBE) bit
    beqz Wrk, serial_putc_loop		// keep looping until ready to send
serial_putc_it:
    andi Top, Top, 0xff				// isolate bottom 8 bits
    sw Top, USART_DATA_OFFSET(Nos)	// write char from Top
serial_putc_done:
	spull Psp, Top
    jal zero, _link	
    
    

