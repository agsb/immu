# https://raw.githubusercontent.com/enthusi/mandelbrot_riscv_assembler/main/gd32vf103.asm

# GD32VF103 Manual: Section 5.3

RCU_BASE_ADDR = 0x40021000

# GD32VF103 Manual: Section 5.3.7

RCU_APB2EN_OFFSET   = 0x18
RCU_APB2EN_AFEN_BIT = 0
RCU_APB2EN_PAEN_BIT = 2
RCU_APB2EN_PBEN_BIT = 3
RCU_APB2EN_PCEN_BIT = 4
RCU_APB2EN_PDEN_BIT = 5
RCU_APB2EN_PEEN_BIT = 6
RCU_APB2EN_SPI0EN_BIT = 12
RCU_APB2EN_USART0EN_BIT = 14

RCU_APB2EN_SPI0EN = (1 << RCU_APB2EN_SPI0EN_BIT )

# GD32VF103 Manual: Section 7.5

AFIO_BASE_ADDR   = 0x40010000

GPIO_BASE_ADDR_A = 0x40010800  # GD32VF103 Manual: Section 7.5 (green and blue LEDs)
GPIO_BASE_ADDR_B = 0x40010C00
GPIO_BASE_ADDR_C = 0x40011000  # GD32VF103 Manual: Section 7.5 (red LED)
GPIO_BASE_ADDR_D = 0x40011400 
GPIO_BASE_ADDR_E = 0x40011800 

GPIO_CTL0_OFFSET  = 0x00 # GPIO port control register 0
GPIO_CTL1_OFFSET  = 0x04 # GPIO port control register 1
GPIO_ISTAT_OFFSET = 0x08 # GPIO port input status register
GPIO_OCTL_OFFSET  = 0x0C # GPIO port output control register
GPIO_BOP_OFFSET   = 0x10 # GPIO port bit operation register
GPIO_BC_OFFSET    = 0x14 # GPIO bit clear register 

# GD32VF103 Manual: Section 7.3

GPIO_MODE_IN        = 0b00
GPIO_MODE_OUT_10MHZ = 0b01
GPIO_MODE_OUT_2MHZ  = 0b10
GPIO_MODE_OUT_50MHZ = 0b11

# GD32VF103 Manual: Section 7.3

GPIO_CTL_IN_ANALOG    = 0b00
GPIO_CTL_IN_FLOATING  = 0b01
GPIO_CTL_IN_PULL_DOWN = 0b10
GPIO_CTL_IN_PULL_UP   = 0b11

# GD32VF103 Manual: Section 7.3

GPIO_CTL_OUT_PUSH_PULL      = 0b00
GPIO_CTL_OUT_OPEN_DRAIN     = 0b01
GPIO_CTL_OUT_ALT_PUSH_PULL  = 0b10
GPIO_CTL_OUT_ALT_OPEN_DRAIN = 0b11

# combined CTL[1:0], MD[1:0]  for config and mode

GPIO_MODE_IN_ANALOG   = 0x0 #  analog input 
GPIO_MODE_PP_10MHZ    = 0x1 #  push-pull output, max speed 10MHz
GPIO_MODE_PP_2MHZ     = 0x2 #  push-pull output, max speed 2MHz
GPIO_MODE_PP_50MHZ    = 0x3 #  push-pull output, max speed 50MHz
GPIO_MODE_IN_FLOAT    = 0x4 #  floating input 
GPIO_MODE_OD_10MHZ    = 0x5 #  open-drain output, max speed 10MHz
GPIO_MODE_OD_2MHZ     = 0x6 #  open-drain output, max speed 2MHz
GPIO_MODE_OD_50MHZ    = 0x7 #  open-drain output, max speed 50MHz
GPIO_MODE_IN_PULL     = 0x8 #  input with pull up/down
GPIO_MODE_AF_PP_10MHZ = 0x9 #  alternate function push-pull, max speed 10MHz
GPIO_MODE_AF_PP_2MHZ  = 0xa #  alternate function push-pull, max speed 2MHz
GPIO_MODE_AF_PP_50MHZ = 0xb #  alternate function push-pull, max speed 50MHz
GPIO_MODE_AF_OD_10MHZ = 0xd #  alternate function open-drain, max speed 10MHz
GPIO_MODE_AF_OD_2MHZ  = 0xe #  alternate function open-drain, max speed 2MHz
GPIO_MODE_AF_OD_50MHZ = 0xf #  alternate function open-drain, max speed

# GD32VF103 Manual: Section 16.4

USART_BASE_ADDR_0 = 0x40013800

# GD32VF103 Manual: Section 16.4.1

USART_STAT_OFFSET   = 0x00
USART_STAT_RBNE_BIT = 5
USART_STAT_TBE_BIT  = 7

# GD32VF103 Manual: Section 16.4.2

USART_DATA_OFFSET = 0x04

# GD32VF103 Manual: Section 16.4.3

USART_BAUD_OFFSET = 0x08

# GD32VF103 Manual: Section 16.4.4

USART_CTL0_OFFSET = 0x0c

# receive 0: disable 1:enable
USART_CTL0_REN_BIT = 2

# transmit 0: disable 1:enable
USART_CTL0_TEN_BIT = 3

# usart 0: disable 1:enable
USART_CTL0_UEN_BIT = 13
  
# use default values 

# data length default 0: 8 data bits 1: 9 data bits
USART_CTL0_WL_BIT = 12

# check parity default 0: parity disable 1: parity enable
USART_CTL0_PCEN_BIT = 10

# check parity default 0: even parity 1: odd  parity
USART_CTL0_PM_BIT = 9

# send break 0: none 1: sent
USART_CTL0_SBKCMD_BIT = 9

USART_CTL1_OFFSET = 0x10

# stop bits, default 00: 1 stop bit 10: 2 stop bit
USART_CTL1_STB1_BIT = 13
USART_CTL0_STB1_BIT = 12

