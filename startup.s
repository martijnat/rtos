.syntax unified
.cpu cortex-m3
.fpu softvfp
.thumb

.global g_pfnVectors
.global Default_Handler

.section .isr_vector,"a",%progbits
.type g_pfnVectors, %object
.size g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
.word  _estack
.word  Reset_Handler
.word  NMI_Handler
.word  HardFault_Handler
.word  MemManage_Handler
.word  BusFault_Handler
.word  UsageFault_Handler
.word  0
.word  0
.word  0
.word  0
.word  SVC_Handler
.word  DebugMon_Handler
.word  0
.word  PendSV_Handler
.word  SysTick_Handler

/* External interrupts for LM3S6965 */
.word  Default_Handler  /* GPIO Port A                      */
.word  Default_Handler  /* GPIO Port B                      */
.word  Default_Handler  /* GPIO Port C                      */
.word  Default_Handler  /* GPIO Port D                      */
.word  Default_Handler  /* GPIO Port E                      */
.word  Default_Handler  /* UART0 Rx and Tx                 */
.word  Default_Handler  /* UART1 Rx and Tx                 */
.word  Default_Handler  /* SSI0 Rx and Tx                  */
.word  Default_Handler  /* I2C0 Master and Slave           */
.word  Default_Handler  /* PWM Fault                        */
.word  Default_Handler  /* PWM Generator 0                  */
.word  Default_Handler  /* PWM Generator 1                  */
.word  Default_Handler  /* PWM Generator 2                  */
.word  Default_Handler  /* Quadrature Encoder 0            */
.word  Default_Handler  /* ADC Sequence 0                   */
.word  Default_Handler  /* ADC Sequence 1                   */
.word  Default_Handler  /* ADC Sequence 2                   */
.word  Default_Handler  /* ADC Sequence 3                   */
.word  Default_Handler  /* Watchdog timer                   */
.word  Default_Handler  /* Timer 0 subtimer A               */
.word  Default_Handler  /* Timer 0 subtimer B               */
.word  Default_Handler  /* Timer 1 subtimer A               */
.word  Default_Handler  /* Timer 1 subtimer B               */
.word  Default_Handler  /* Timer 2 subtimer A               */
.word  Default_Handler  /* Timer 2 subtimer B               */
.word  Default_Handler  /* Analog Comparator 0              */
.word  Default_Handler  /* Analog Comparator 1              */
.word  Default_Handler  /* Analog Comparator 2              */
.word  Default_Handler  /* System Control (PLL, OSC, BO)   */
.word  Default_Handler  /* FLASH Control                    */

.section .text.Reset_Handler
.weak Reset_Handler
.type Reset_Handler, %function

Reset_Handler:
    ldr   sp, =_estack      /* Set stack pointer */

    /* Copy data from flash to RAM */
    movs  r1, #0
    b     LoopCopyDataInit

CopyDataInit:
    ldr   r3, =_sidata
    ldr   r3, [r3, r1]
    str   r3, [r0, r1]
    adds  r1, r1, #4

LoopCopyDataInit:
    ldr   r0, =_sdata
    ldr   r3, =_edata
    adds  r2, r0, r1
    cmp   r2, r3
    bcc   CopyDataInit
    ldr   r2, =_sbss
    b     LoopFillZerobss

FillZerobss:
    movs  r3, #0
    str   r3, [r2], #4

LoopFillZerobss:
    ldr   r3, = _ebss
    cmp   r2, r3
    bcc   FillZerobss

    /* Call SystemInit if it exists */
    ldr   r0, =SystemInit
    cmp   r0, #0
    beq   skip_system_init
    blx   r0
skip_system_init:

    /* Call main */
    bl    main
    bx    lr

.size Reset_Handler, .-Reset_Handler

/* Default handler */
.section .text.Default_Handler,"ax",%progbits
Default_Handler:
Infinite_Loop:
    b  Infinite_Loop
.size Default_Handler, .-Default_Handler

/* Weak definitions for interrupt handlers */
.weak NMI_Handler
.thumb_set NMI_Handler,Default_Handler

.weak HardFault_Handler
.thumb_set HardFault_Handler,Default_Handler

.weak MemManage_Handler
.thumb_set MemManage_Handler,Default_Handler

.weak BusFault_Handler
.thumb_set BusFault_Handler,Default_Handler

.weak UsageFault_Handler
.thumb_set UsageFault_Handler,Default_Handler

.weak SVC_Handler
.thumb_set SVC_Handler,Default_Handler

.weak DebugMon_Handler
.thumb_set DebugMon_Handler,Default_Handler

.weak PendSV_Handler
.thumb_set PendSV_Handler,Default_Handler

.weak SysTick_Handler
.thumb_set SysTick_Handler,Default_Handler
