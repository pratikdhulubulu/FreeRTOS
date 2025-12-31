.syntax unified
.cpu cortex-m4
.thumb

.global _estack
.global Reset_Handler

_estack = 0x20020000

.section .isr_vector, "a", %progbits
.word _estack
.word Reset_Handler
.word Default_Handler
.word Default_Handler
.word Default_Handler
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word SVC_Handler
.word 0
.word 0
.word PendSV_Handler
.word SysTick_Handler

.section .text.Reset_Handler
.thumb_func
Reset_Handler:
    ldr r0, =_sdata
    ldr r1, =_edata
    ldr r2, =_sidata
1:
    cmp r0, r1
    ittt lt
    ldrlt r3, [r2], #4
    strlt r3, [r0], #4
    blt 1b

    ldr r0, =_sbss
    ldr r1, =_ebss
    movs r2, #0
2:
    cmp r0, r1
    it lt
    strlt r2, [r0], #4
    blt 2b

    bl main
    b .

.section .text.Default_Handler
.thumb_func
Default_Handler:
    b .

/* ---- FreeRTOS handler mapping ---- */
.weak SVC_Handler
.weak PendSV_Handler
.weak SysTick_Handler

.thumb_set SVC_Handler, vPortSVCHandler
.thumb_set PendSV_Handler, xPortPendSVHandler
.thumb_set SysTick_Handler, xPortSysTickHandler
