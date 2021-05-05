            TTL Exercise 5 Polled Serial I/O
;****************************************************************
;Serial Input and Output on the KL05Z Freedom Board using UART0 
; polling
;Name:  Shubhang Mehrotra
;Date:  03/04/2021
;Class:  CMPE-250
;Section:  01 Thursday 2 PM 
;---------------------------------------------------------------
;Keil Template for KL05
;R. W. Melton
;September 13, 2020
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET  MKL05Z4.s     ;Included by start.s
            OPT  1   ;Turn on listing
;****************************************************************
;EQUates
;Characters
CR    EQU  0x0D
LF    EQU  0x0A
NULL  EQU  0x00
;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
;Port B
PORT_PCR_SET_PTB2_UART0_RX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
PORT_PCR_SET_PTB1_UART0_TX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
;---------------------------------------------------------------
;SIM_SCGC4
;1->10:UART0 clock gate control (enabled)
;Use provided SIM_SCGC4_UART0_MASK
;---------------------------------------------------------------
;SIM_SCGC5
;1->10:Port B clock gate control (enabled)
;Use provided SIM_SCGC5_PORTB_MASK
;---------------------------------------------------------------
;SIM_SOPT2
;01=27-26:UART0SRC=UART0 clock source select (MCGFLLCLK)
;---------------------------------------------------------------
SIM_SOPT2_UART0SRC_MCGFLLCLK  EQU  \
                                 (1 << SIM_SOPT2_UART0SRC_SHIFT)
;---------------------------------------------------------------
;SIM_SOPT5
; 0->   16:UART0 open drain enable (disabled)
; 0->   02:UART0 receive data select (UART0_RX)
;00->01-00:UART0 transmit data select source (UART0_TX)
SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  EQU  \
                               (SIM_SOPT5_UART0ODE_MASK :OR: \
                                SIM_SOPT5_UART0RXSRC_MASK :OR: \
                                SIM_SOPT5_UART0TXSRC_MASK)
;---------------------------------------------------------------
;UART0_BDH
;    0->  7:LIN break detect IE (disabled)
;    0->  6:RxD input active edge IE (disabled)
;    0->  5:Stop bit number select (1)
;00001->4-0:SBR[12:0] (UART0CLK / [9600 * (OSR + 1)]) 
;UART0CLK is MCGFLLCLK
;MCGPLLCLK is 47972352 Hz ~=~ 48 MHz
;SBR ~=~ 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
;SBR = 47972352 / (9600 * 16) = 312.32 --> 312 = 0x138
UART0_BDH_9600  EQU  0x01
;---------------------------------------------------------------
;UART0_BDL
;26->7-0:SBR[7:0] (UART0CLK / [9600 * (OSR + 1)])
;UART0CLK is MCGFLLCLK
;MCGPLLCLK is 47972352 Hz ~=~ 48 MHz
;SBR ~=~ 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
;SBR = 47972352 / (9600 * 16) = 312.32 --> 312 = 0x138
UART0_BDL_9600  EQU  0x38
;---------------------------------------------------------------
;UART0_C1
;0-->7:LOOPS=loops select (normal)
;0-->6:DOZEEN=doze enable (disabled)
;0-->5:RSRC=receiver source select (internal--no effect LOOPS=0)
;0-->4:M=9- or 8-bit mode select 
;        (1 start, 8 data [lsb first], 1 stop)
;0-->3:WAKE=receiver wakeup method select (idle)
;0-->2:IDLE=idle line type select (idle begins after start bit)
;0-->1:PE=parity enable (disabled)
;0-->0:PT=parity type (even parity--no effect PE=0)
UART0_C1_8N1  EQU  0x00
;---------------------------------------------------------------
;UART0_C2
;0-->7:TIE=transmit IE for TDRE (disabled)
;0-->6:TCIE=transmission complete IE for TC (disabled)
;0-->5:RIE=receiver IE for RDRF (disabled)
;0-->4:ILIE=idle line IE for IDLE (disabled)
;1-->3:TE=transmitter enable (enabled)
;1-->2:RE=receiver enable (enabled)
;0-->1:RWU=receiver wakeup control (normal)
;0-->0:SBK=send break (disabled, normal)
UART0_C2_T_R  EQU  (UART0_C2_TE_MASK :OR: UART0_C2_RE_MASK)
;---------------------------------------------------------------
;UART0_C3
;0-->7:R8T9=9th data bit for receiver (not used M=0)
;           10th data bit for transmitter (not used M10=0)
;0-->6:R9T8=9th data bit for transmitter (not used M=0)
;           10th data bit for receiver (not used M10=0)
;0-->5:TXDIR=UART_TX pin direction in single-wire mode
;            (no effect LOOPS=0)
;0-->4:TXINV=transmit data inversion (not inverted)
;0-->3:ORIE=overrun IE for OR (disabled)
;0-->2:NEIE=noise error IE for NF (disabled)
;0-->1:FEIE=framing error IE for FE (disabled)
;0-->0:PEIE=parity error IE for PF (disabled)
UART0_C3_NO_TXINV  EQU  0x00
;---------------------------------------------------------------
;UART0_C4
;    0-->  7:MAEN1=match address mode enable 1 (disabled)
;    0-->  6:MAEN2=match address mode enable 2 (disabled)
;    0-->  5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
;               = 1 + OSR for 3 <= OSR <= 31
;               = 16 for 0 <= OSR <= 2 (invalid values)
UART0_C4_OSR_16           EQU  0x0F
UART0_C4_NO_MATCH_OSR_16  EQU  UART0_C4_OSR_16
;---------------------------------------------------------------
;UART0_C5
;  0-->  7:TDMAE=transmitter DMA enable (disabled)
;  0-->  6:Reserved; read-only; always 0
;  0-->  5:RDMAE=receiver full DMA enable (disabled)
;000-->4-2:Reserved; read-only; always 0
;  0-->  1:BOTHEDGE=both edge sampling (rising edge only)
;  0-->  0:RESYNCDIS=resynchronization disable (enabled)
UART0_C5_NO_DMA_SSR_SYNC  EQU  0x00
;---------------------------------------------------------------
;UART0_S1
;0-->7:TDRE=transmit data register empty flag; read-only
;0-->6:TC=transmission complete flag; read-only
;0-->5:RDRF=receive data register full flag; read-only
;1-->4:IDLE=idle line flag; write 1 to clear (clear)
;1-->3:OR=receiver overrun flag; write 1 to clear (clear)
;1-->2:NF=noise flag; write 1 to clear (clear)
;1-->1:FE=framing error flag; write 1 to clear (clear)
;1-->0:PF=parity error flag; write 1 to clear (clear)
UART0_S1_CLEAR_FLAGS  EQU  (UART0_S1_IDLE_MASK :OR: \
                            UART0_S1_OR_MASK :OR: \
                            UART0_S1_NF_MASK :OR: \
                            UART0_S1_FE_MASK :OR: \
                            UART0_S1_PF_MASK)
;---------------------------------------------------------------
;UART0_S2
;1-->7:LBKDIF=LIN break detect interrupt flag (clear)
;             write 1 to clear
;1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)
;              write 1 to clear
;0-->5:(reserved); read-only; always 0
;0-->4:RXINV=receive data inversion (disabled)
;0-->3:RWUID=receive wake-up idle detect
;0-->2:BRK13=break character generation length (10)
;0-->1:LBKDE=LIN break detect enable (disabled)
;0-->0:RAF=receiver active flag; read-only
UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  EQU  \
        (UART0_S2_LBKDIF_MASK :OR: UART0_S2_RXEDGIF_MASK)
;---------------------------------------------------------------
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
				
			EXPORT  PutChar	
			IMPORT  Carry
            IMPORT  Negative				
			IMPORT	Overflow
			IMPORT  PutPrompt
            IMPORT  Zero
				
Reset_Handler  PROC  {}
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL05 system startup with 48-MHz system clock
            BL      Startup
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<
            BL      Init_UART0_Polling
prompt
			BL      PutPrompt	
loop      
			BL      GetChar
			BL      PutChar
			CMP     R0,#CR
			BEQ     Ins_LF
			
			;capitalizing the letters
			CMP     R0,#'a'           
		    BLO     char_subRoutine
			
			CMP     R0,#'z'
			BHI     char_subRoutine
			SUBS    R0,R0,#'a'            ;removing the ascii of small letter
			ADDS    R0,R0,#'A'            ;putting the ascii of the capital letter 
			;**************************
			
char_subRoutine			
			;perform character subroutine
			CMP     R0,#'C'
			BEQ     C_subRoutine
			
			CMP     R0,#'N'
			BEQ     N_subRoutine
			
			CMP     R0,#'V'
			BEQ     V_subRoutine
			
			CMP     R0,#'Z'
			BEQ     Z_subRoutine
			;****************************
			B       loop

Ins_LF      MOVS    R0,#LF
            BL      PutChar
            B       prompt
		
C_subRoutine
            BL       Carry
			B        prompt
			
N_subRoutine
            BL       Negative
			B        prompt
			
V_subRoutine
            BL       Overflow
			B        prompt

Z_subRoutine
            BL       Zero
			B        prompt
		
;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP
;>>>>> begin subroutine code <<<<<
Init_UART0_Polling  PROC {R0-R14}
; Select/Configure UART0 Sources
; Enable clocks for UART0 and Port B
; Select port B mux pins to connect to UART0 
; Configure UART0(register initialization)


             PUSH  {R0, R1, R2}           ;Register retention
			 
			 LDR   R0,=SIM_SOPT2            ;connect Sources
             LDR   R1,=SIM_SOPT2_UART0SRC_MASK
             LDR   R2,[R0,#0]               ;current SIM_SOPT2 value
             BICS  R2,R2,R1                 ;bits cleared of UART0SRC
             LDR   R1,=SIM_SOPT2_UART0SRC_MCGFLLCLK  
             ORRS  R2,R2,R1                 ;UART0 bits changed
             STR   R2,[R0,#0]               ;update SIM_SOPT2
			  
			 LDR   R0,=SIM_SOPT5            ;set SIM_SOPT5 for UART0 external
             LDR   R1,= SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
             LDR   R2,[R0,#0]
             BICS  R2,R2,R1
             STR   R2,[R0,#0]
			  
			 LDR   R0,=SIM_SCGC4          ;enable SIM_SCGC4 as clock for UART0 Module
			 LDR   R1,=SIM_SCGC4_UART0_MASK 
             LDR   R2,[R0,#0]
			 ORRS  R2,R2,R1
			 STR   R2,[R0,#0]
			   
			 LDR   R0,=SIM_SCGC5          ;enable clock for Port B module
             LDR   R1,= SIM_SCGC5_PORTB_MASK
             LDR   R2,[R0,#0]
             ORRS  R2,R2,R1
             STR   R2,[R0,#0]
			 
			 LDR   R0,=PORTB_PCR2         ;connect Port B pin 1 to UART0 Rx
             LDR   R1,=PORT_PCR_SET_PTB2_UART0_RX
             STR   R1,[R0,#0]
			 
			 LDR   R0,=PORTB_PCR1         ;connect Port B pin 2 to UART0 Tx
             LDR   R1,=PORT_PCR_SET_PTB1_UART0_TX
             STR   R1,[R0,#0]
			 
			 
			 LDR   R0,=UART0_BASE         ;load base address
			 
             MOVS  R1,#UART0_C2_T_R       ;Diasble UART0
             LDRB  R2,[R0,#UART0_C2_OFFSET]
             BICS  R2,R2,R1
             STRB  R2,[R0,#UART0_C2_OFFSET]
			 
			 MOVS  R1,#UART0_BDH_9600     ;set UART0 baud rate
             STRB  R1,[R0,#UART0_BDH_OFFSET]
             MOVS  R1,#UART0_BDL_9600
             STRB  R1,[R0,#UART0_BDL_OFFSET]
			 
             MOVS  R1,#UART0_C1_8N1        ;set UART0 8 bit serial stream 
             STRB  R1,[R0,#UART0_C1_OFFSET]
             MOVS  R1,#UART0_C3_NO_TXINV
             STRB  R1,[R0,#UART0_C3_OFFSET]
             MOVS  R1,#UART0_C4_NO_MATCH_OSR_16
             STRB  R1,[R0,#UART0_C4_OFFSET]
             MOVS  R1,#UART0_C5_NO_DMA_SSR_SYNC
             STRB  R1,[R0,#UART0_C5_OFFSET]
             MOVS  R1,#UART0_S1_CLEAR_FLAGS
             STRB  R1,[R0,#UART0_S1_OFFSET]
             MOVS  R1,#UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
             STRB  R1,[R0,#UART0_S2_OFFSET] 
			 
			 MOVS  R1,#UART0_C2_T_R        ;Enable UART0
             STRB  R1,[R0,#UART0_C2_OFFSET]
			 
			 POP   {R0,R1,R2}              ;Register retention 
			 
			 BX LR                         ;exit subroutine
             ENDP             
			 
GetChar      PROC {R1-R14}
;/* Output:  R0:  Character received */
; repeat 
;      {check RDRF bit of UART0_S1
;   }until (RDRF= 1)
; get character received from UART0_D
; return }
            PUSH  {R1, R2, R3}                ;Register retention
			
			LDR   R1, =UART0_BASE
			MOVS  R2, #UART0_S1_RDRF_MASK
			
repeat_get  LDRB  R3, [R1, #UART0_S1_OFFSET]
			ANDS  R3, R3, R2
			BEQ	  repeat_get
			
			LDRB  R0, [R1, #UART0_D_OFFSET]    ;load value into R1 
			
			POP   {R1, R2, R3}                 ;register retention
			
			BX    LR						   ;exit subroutine
            ENDP

PutChar     PROC {R0-R14}
;/*Input: R0: Character to transmit */
; repeat{
;    check TDRE bit of UART0_S1
; } until(TDRE == 1)
; put character to transmit into UART0_D
; return }
            
			PUSH  {R1, R2, R3}                ;register retention 
			
			LDR   R1, =UART0_BASE             ;get value of TDRE
			MOVS  R2, #UART0_S1_TDRE_MASK
			
repeat_put
			LDRB  R3, [R1, #UART0_S1_OFFSET]
			ANDS  R3, R3, R2                  ;check to see if ready for loading 
			BEQ   repeat_put                  ;repeat unitl ready 
			
			
			STRB R0, [R1, #UART0_D_OFFSET]    ;transmit characters from R0
			
	
			POP {R1, R2, R3}                  ;register retention
			
			BX LR                             ;exit subroutine
            
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
            IMPORT  __initial_sp
            IMPORT  Dummy_Handler
            IMPORT  HardFault_Handler
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;01:reset vector
            DCD    Dummy_Handler      ;02:NMI
            DCD    HardFault_Handler  ;03:hard fault
            DCD    Dummy_Handler      ;04:(reserved)
            DCD    Dummy_Handler      ;05:(reserved)
            DCD    Dummy_Handler      ;06:(reserved)
            DCD    Dummy_Handler      ;07:(reserved)
            DCD    Dummy_Handler      ;08:(reserved)
            DCD    Dummy_Handler      ;09:(reserved)
            DCD    Dummy_Handler      ;10:(reserved)
            DCD    Dummy_Handler      ;11:SVCall (supervisor call)
            DCD    Dummy_Handler      ;12:(reserved)
            DCD    Dummy_Handler      ;13:(reserved)
            DCD    Dummy_Handler      ;14:PendSV (PendableSrvReq)
                                      ;   pendable request 
                                      ;   for system service)
            DCD    Dummy_Handler      ;15:SysTick (system tick timer)
            DCD    Dummy_Handler      ;16:DMA channel 0 transfer 
                                      ;   complete/error
            DCD    Dummy_Handler      ;17:DMA channel 1 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;18:DMA channel 2 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;19:DMA channel 3 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;20:(reserved)
            DCD    Dummy_Handler      ;21:FTFA command complete/
                                      ;   read collision
            DCD    Dummy_Handler      ;22:low-voltage detect;
                                      ;   low-voltage warning
            DCD    Dummy_Handler      ;23:low leakage wakeup
            DCD    Dummy_Handler      ;24:I2C0
            DCD    Dummy_Handler      ;25:(reserved)
            DCD    Dummy_Handler      ;26:SPI0
            DCD    Dummy_Handler      ;27:(reserved)
            DCD    Dummy_Handler      ;28:UART0 (status; error)
            DCD    Dummy_Handler      ;29:(reserved)
            DCD    Dummy_Handler      ;30:(reserved)
            DCD    Dummy_Handler      ;31:ADC0
            DCD    Dummy_Handler      ;32:CMP0
            DCD    Dummy_Handler      ;33:TPM0
            DCD    Dummy_Handler      ;34:TPM1
            DCD    Dummy_Handler      ;35:(reserved)
            DCD    Dummy_Handler      ;36:RTC (alarm)
            DCD    Dummy_Handler      ;37:RTC (seconds)
            DCD    Dummy_Handler      ;38:PIT
            DCD    Dummy_Handler      ;39:(reserved)
            DCD    Dummy_Handler      ;40:(reserved)
            DCD    Dummy_Handler      ;41:DAC0
            DCD    Dummy_Handler      ;42:TSI0
            DCD    Dummy_Handler      ;43:MCG
            DCD    Dummy_Handler      ;44:LPTMR0
            DCD    Dummy_Handler      ;45:(reserved)
            DCD    Dummy_Handler      ;46:PORTA
            DCD    Dummy_Handler      ;47:PORTB
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
;>>>>>   end variables here <<<<<
            ALIGN
            END
