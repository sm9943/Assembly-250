            TTL Program Iteration and Subroutines Lab 4
;****************************************************************
; Iteration and Subroutines, Lab 4
;Name:  Shubhang Mehrotra
;Date:  02/18/2021
;Class:  CMPE-250
;Section:  Section 1 Thursday 2 PM
;---------------------------------------------------------------
;Keil Simulator Template for KL05
;R. W. Melton
;January 21, 2021
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;EQUates
MAX_DATA          EQU  25 
;Standard data masks
BYTE_MASK         EQU  0xFF
NIBBLE_MASK       EQU  0x0F
;Standard data sizes (in bits)
BYTE_BITS         EQU  8
NIBBLE_BITS       EQU  4
;Architecture data sizes (in bytes)
WORD_SIZE         EQU  4  ;Cortex-M0+
HALFWORD_SIZE     EQU  2  ;Cortex-M0+
;Architecture data masks
HALFWORD_MASK     EQU  0xFFFF
;Return                 
RET_ADDR_T_MASK   EQU  1  ;Bit 0 of ret. addr. must be
                          ;set for BX, BLX, or POP
                          ;mask in thumb mode
;---------------------------------------------------------------
;Vectors
VECTOR_TABLE_SIZE EQU 0x000000C0  ;KL05
VECTOR_SIZE       EQU 4           ;Bytes per vector
;---------------------------------------------------------------
;CPU CONTROL:  Control register
;31-2:(reserved)
;   1:SPSEL=current stack pointer select
;           0=MSP (main stack pointer) (reset value)
;           1=PSP (process stack pointer)
;   0:nPRIV=not privileged
;        0=privileged (Freescale/NXP "supervisor") (reset value)
;        1=not privileged (Freescale/NXP "user")
CONTROL_SPSEL_MASK   EQU  2
CONTROL_SPSEL_SHIFT  EQU  1
CONTROL_nPRIV_MASK   EQU  1
CONTROL_nPRIV_SHIFT  EQU  0
;---------------------------------------------------------------
;CPU PRIMASK:  Interrupt mask register
;31-1:(reserved)
;   0:PM=prioritizable interrupt mask:
;        0=all interrupts unmasked (reset value)
;          (value after CPSIE I instruction)
;        1=prioritizable interrrupts masked
;          (value after CPSID I instruction)
PRIMASK_PM_MASK   EQU  1
PRIMASK_PM_SHIFT  EQU  0
;---------------------------------------------------------------
;CPU PSR:  Program status register
;Combined APSR, EPSR, and IPSR
;----------------------------------------------------------
;CPU APSR:  Application Program Status Register
;31  :N=negative flag
;30  :Z=zero flag
;29  :C=carry flag
;28  :V=overflow flag
;27-0:(reserved)
APSR_MASK     EQU  0xF0000000
APSR_SHIFT    EQU  28
APSR_N_MASK   EQU  0x80000000
APSR_N_SHIFT  EQU  31
APSR_Z_MASK   EQU  0x40000000
APSR_Z_SHIFT  EQU  30
APSR_C_MASK   EQU  0x20000000
APSR_C_SHIFT  EQU  29
APSR_V_MASK   EQU  0x10000000
APSR_V_SHIFT  EQU  28
;----------------------------------------------------------
;CPU EPSR
;31-25:(reserved)
;   24:T=Thumb state bit
;23- 0:(reserved)
EPSR_MASK     EQU  0x01000000
EPSR_SHIFT    EQU  24
EPSR_T_MASK   EQU  0x01000000
EPSR_T_SHIFT  EQU  24
;----------------------------------------------------------
;CPU IPSR
;31-6:(reserved)
; 5-0:Exception number=number of current exception
;      0=thread mode
;      1:(reserved)
;      2=NMI
;      3=hard fault
;      4-10:(reserved)
;     11=SVCall
;     12-13:(reserved)
;     14=PendSV
;     15=SysTick
;     16=IRQ0
;     16-47:IRQ(Exception number - 16)
;     47=IRQ31
;     48-63:(reserved)
IPSR_MASK             EQU  0x0000003F
IPSR_SHIFT            EQU  0
IPSR_EXCEPTION_MASK   EQU  0x0000003F
IPSR_EXCEPTION_SHIFT  EQU  0
;----------------------------------------------------------
PSR_N_MASK           EQU  APSR_N_MASK
PSR_N_SHIFT          EQU  APSR_N_SHIFT
PSR_Z_MASK           EQU  APSR_Z_MASK
PSR_Z_SHIFT          EQU  APSR_Z_SHIFT
PSR_C_MASK           EQU  APSR_C_MASK
PSR_C_SHIFT          EQU  APSR_C_SHIFT
PSR_V_MASK           EQU  APSR_V_MASK
PSR_V_SHIFT          EQU  APSR_V_SHIFT
PSR_T_MASK           EQU  EPSR_T_MASK
PSR_T_SHIFT          EQU  EPSR_T_SHIFT
PSR_EXCEPTION_MASK   EQU  IPSR_EXCEPTION_MASK
PSR_EXCEPTION_SHIFT  EQU  IPSR_EXCEPTION_SHIFT
;----------------------------------------------------------
;Stack
SSTACK_SIZE EQU  0x00000100
;****************************************************************
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
			IMPORT  InitData
            IMPORT  LoadData
            IMPORT  TestData 
				
            EXPORT  Reset_Handler
			EXPORT  P
            EXPORT 	Q
            EXPORT  Results				
			 				
Reset_Handler  PROC {}
main
;---------------------------------------------------------------
;Initialize registers R0-R12
            BL      RegInit
            
;>>>>> begin main program code <<<<<
; Inputs:
; R0: Divisor (unsigned)
; R1: Dividend (unsigned)
; 
; Outputs: 
; R0: Quotient (unsigned)
; R1: Remainder (unsigned)
;  C: ASPR Flag, 0 for Valid Result, 1 for invalid. 
;
; Constraints: 
; R6 and R7 must not be modified: Testing 

            BL      InitData           ; Initializing Data
                                       
            LDR     R2,=P              ; Loading the Address of P
            LDR     R3,=Q              ; Loading the address of Q
                                       
WHILE       BL      LoadData           ; Loading Data
            BCS     DONE               ; Loop Check -> If 'C' flag is set, end loop. 
                                       
            LDR     R1,[R2,#0]         ; Load value of P into R1
            LDR     R0,[R3,#0]         ; Load value of Q into R0
            BL      DIVU               ; Call Unsigned integer Division subroutine
                                       
            BCC     IS_VALID           ; If C is set -> invalid result,
                                       ; Otherwise valid -> Continue.

            LDR     R0,=0xFFFFFFFF     ; If C flag is set, set values into R0 
            LDR     R1,=0xFFFFFFFF     ; and R1. 

                                       ; If everything is valid. 
IS_VALID    STR     R0,[R2,#0]         ; Store the value of P into R0 -> Quotient  
            STR     R1,[R3,#0]         ; Store the value of Q into R1 -> Remainder
            BL      TestData           ; Branch to TestData subroutine in the Lib file
            B       WHILE              ; Loop call. 

DONE

;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP
;---------------------------------------------------------------
RegInit     PROC  {}
;****************************************************************
;Initializes register n to value 0xnnnnnnnn, for n in 
;{0x0-0xC,0xE}
;****************************************************************
;Put return on stack
            PUSH    {LR}
;Initialize registers
            LDR     R1,=0x11111111
            ADDS    R2,R1,R1
            ADDS    R3,R2,R1
            ADDS    R4,R3,R1
            ADDS    R5,R4,R1
            ADDS    R6,R5,R1
            ADDS    R7,R6,R1
            ADDS    R0,R7,R1
            MOV     R8,R0
            ADDS    R0,R0,R1
            MOV     R9,R0
            ADDS    R0,R0,R1
            MOV     R10,R0
            ADDS    R0,R0,R1
            MOV     R11,R0
            ADDS    R0,R0,R1
            MOV     R12,R0
            ADDS    R0,R0,R1
            ADDS    R0,R0,R1
            MOV     R14,R0
            MOVS    R0,#0
            POP     {PC}
            ENDP
;---------------------------------------------------------------
;>>>>> begin subroutine code <<<<<
DIVU        PROC    {R2-R14}           
;****************************************************************
; Performs the division operation upon R1 by dividing it from R0
; and returning the Quotient and Remainder in R0 and R1 
; respectively. If Division by 0 is top be performed, R0 and R1 
; do not change their values, instead C bit is set.
;
; R0 rem R1 = R1 / R0 
;****************************************************************
            PUSH     {R2-R3}      ;Temporary Registers  
            CMP      R0, #0       ;Check for division by 0
            BEQ      DIV_BY_0
            CMP      R1, #0       ;Check for division of 0			
            BEQ      DIV_OF_0
			
			MOVS     R2, R0       ;Temporarily storing the dividend
			MOVS     R0, #0       ;Initializing the quotient

While       CMP      R1,R2        ;check for Dividend >= Divisor
            BLO      DIV_END
            SUBS     R1,R1,R2     ;Dividend -= Divisor
            ADDS	 R0,R0,#1	  ;Quotient++
			B        While
			
DIV_END     MRS      R2, APSR     ;Clear flags.
            MOVS     R3, #0x20    ;Create Mask
			LSLS     R3,R3,#24    ;Shift to MSB
			BICS     R2,R3        ;
			MSR      APSR, R2

DIV_DONE    POP      {R2-R3}       ;Store Temporary Registers.
            BX       LR
			
DIV_OF_0    MOVS     R0, #0        ;Set Quotient = 0
            MOVS     R1, #0        ;Set Remainder = 0
			B        DIV_END

DIV_BY_0    MRS      R2, APSR      ;Clear all flags
            MOVS     R3, #0x20     ;Mask
			LSLS     R3,R3,#24
			ORRS     R2,R3
			MSR      APSR,R2       ;Set C Flag
			B        DIV_DONE
			ENDP
;>>>>>   end subroutine code <<<<<
            ALIGN
;****************************************************************
;Vector Table Mapped to Address 0 at Reset
;Linker requires __Vectors to be exported
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;reset vector
            SPACE  (VECTOR_TABLE_SIZE - (2 * VECTOR_SIZE))
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
;>>>>>   end constants here <<<<<
;****************************************************************
            AREA    |.ARM.__at_0x1FFFFC00|,DATA,READWRITE,ALIGN=3
            EXPORT  __initial_sp
;Allocate system stack
            IF      :LNOT::DEF:SSTACK_SIZE
SSTACK_SIZE EQU     0x00000100
            ENDIF
Stack_Mem   SPACE   SSTACK_SIZE
__initial_sp
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
P           SPACE   4
Q           SPACE	4

;Results must be defined as a Word Array with 2 x MAX_DATA elements	
Results     SPACE   2*MAX_DATA
;>>>>>   end variables here <<<<<
            END