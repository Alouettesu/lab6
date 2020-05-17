        NAME    startup

FIQ_BIT equ      0x00000040       ; FIQ exception enable/disable bit
IRQ_BIT equ      0x00000080       ; IRQ exception enable/disable bit
EXCEPTION_VECT equ   0x00000000   ; Start of exception vectors
; Constants that define various operating modes
PSR_MASK equ    0x0000001F       ; CSPR bits that define operating mode
MODE_USR equ    0x00000010       ; User Mode
MODE_FIQ equ    0x00000011       ; FIQ Mode
MODE_IRQ equ    0x00000012       ; IRQ Mode
MODE_SVC equ    0x00000013       ; Supervisor Mode
MODE_ABT equ    0x00000017       ; Abort Mode
MODE_UND equ    0x0000001B       ; Undefined Mode
MODE_SYS equ    0x0000001F       ; System Mode


        PUBLIC  __iar_program_start
        //PUBLIC __iar_data_init3
        //PUBLIC __iar_zero_init3
        PUBLIC  vectors_start
        EXTERN main
        EXTERN __init
        EXTERN vPortYieldProcessor
        EXTERN vFreeRTOS_ISR
        
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION SVC_STACK:DATA:NOROOT(3)
        SECTION IRQ_STACK:DATA:NOROOT(3)
        SECTION .bss:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT (2)


vectors_start

        ARM

        ; Only the reset handler is required.
        LDR     PC,Reset_Addr           ; Reset
        LDR     PC,Undefined_Addr       ; Undefined instructions
        LDR     PC,SVC_Addr             ; Software interrupt (SWI/SVC)
        LDR     PC,Prefetch_Addr        ; Prefetch abort
        LDR     PC,Abort_Addr           ; Data abort
        DCD     0                       ; RESERVED
        LDR     PC,IRQ_Addr             ; IRQ
        LDR     PC,FIQ_Addr             ; FIQ

        DATA

Reset_Addr:     DCD   __iar_program_start
Undefined_Addr: DCD   Undefined_Handler
SVC_Addr:       DCD   vPortYieldProcessor;SVC_Handler
Prefetch_Addr:  DCD   Prefetch_Handler
Abort_Addr:     DCD   Abort_Handler
IRQ_Addr:       DCD   vFreeRTOS_ISR;IRQ_Handler
FIQ_Addr:       DCD   FIQ_Handler
stack_top:      DCD   sfe(CSTACK)
svc_stack_top:  DCD   sfe(SVC_STACK)
irq_stack_top:  DCD   sfe(IRQ_STACK)
__bss_begin_addr: DCD   sfb(.bss)
__bss_end_addr:   DCD   sfe(.bss)

        ARM

__iar_program_start
    ;The handler is always entered in Supervisor mode
    LDR sp, svc_stack_top                 ; stack for the supervisor mode
    
    ;  In the reset handler, we need to copy our interrupt vector table to 0x0000, its currently at 0x10000
    LDR r0, =vectors_start                 ; Store the source pointer
    MOV r1, #EXCEPTION_VECT               ; Store the destination pointer.
    ;  Copy the branching instructions from vectors start to registers r2-r9 and then to destination
    LDMIA r0!, {r2, r3, r4, r5, r6, r7, r8, r9}     ; Load multiple values from indexed address; auto-increment R0
    STMIA r1!, {r2, r3, r4, r5, r6, r7, r8, r9}     ; Store multiple values from the indexed address; auto-increment R1


    ;  Also copy correct addresses of exception handlers
    LDMIA r0!, {r2, r3, r4, r5, r6, r7, r8, r9}
    STMIA r1!, {r2, r3, r4, r5, r6, r7, r8, r9}


    ; Clear the whole BSS section to 0:
    LDR r0, __bss_begin_addr
    LDR r1, __bss_end_addr
    MOV r2, #0
bss_clear_loop:
    CMP r0, r1                     ; if (r0<r1) ....
    STRLTB r2, [r0], #1            ; ...store a byte of r2 (i.r. 0) to location pointed by r0++
    BLT bss_clear_loop             ; ...and continue the loop


    ; Set stack pointers and IRQ/FIQ bits for all supported operating modes

    MRS r0, cpsr                           ; copy Program Status Register (CPSR) to r0

    ; Disable IRQ and FIQ interrupts for the Supervisor mode
    ; This should be disabled by default, but it doesn't hurt...
    ORR r1, r0, #IRQ_BIT|FIQ_BIT
    MSR cpsr, r1

    ; Switch to System mode and disable IRQ/FIQ
    BIC r1, r0, #PSR_MASK                  ; clear lowest 5 bits
    ORR r1, r1, #MODE_SYS                  ; and set them to the System mode
    ORR r1, r1, #IRQ_BIT|FIQ_BIT           ; disable IRQ and FIW triggering
    MSR cpsr, r1                           ; update CPSR and enter System mode
    LDR sp, stack_top                     ; set stack for System mode

    ; Set and switch into IRQ mode
    BIC r1, r0, #PSR_MASK                  ; clear least significant 5 bits...
    ORR r1, r1, #MODE_IRQ                  ; and set them to b10010 (0x12), i.e set IRQ mode
    ORR r1, r1, #IRQ_BIT|FIQ_BIT           ; also disable IRQ and FIQ triggering (a default setting, but...)
    MSR cpsr, r1                           ; update CPSR (program status register) for IRQ mode

    ; When in IRQ mode, set its stack pointer
    LDR sp, irq_stack_top                 ; stack for the IRQ mode

    ; Prepare and enter into System mode.
    BIC r1, r0, #PSR_MASK                  ; clear lowest 5 bits
    ORR r1, r1, #MODE_SYS                  ; and set them to the System mode

    ; Return to Supervisor mode. When the first task starts it will switch
    ; to System mode and enable IRQ triggering.
    BIC r1, r1, #PSR_MASK
    ORR r1, r1, #MODE_SVC
    MSR cpsr, r1

    BL __init                               ; before the application is started, initialize all hardware


        B main
       
Undefined_Handler
SVC_Handler
Prefetch_Handler
Abort_Handler
IRQ_Handler
FIQ_Handler
__default_handler
        B __default_handler
       
        END
