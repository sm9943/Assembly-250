            TTL Exercise 6 Secure String I/O and Number Output
;****************************************************************
; Utilizes the GetStringSB and PutStringSB subroutines to handle
; secure string input and output by preventing buffer overrun 
; and null terminating the strings. 
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
            OPT  1             ;Turn on listing
;****************************************************************
;EQUates
MAX_STRING	EQU 79
	
;Characters
CR    EQU  0x0D
LF    EQU  0x0A
BS    EQU  0x08 	
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
			
			IMPORT  LengthStringSB
				
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

PUT_PROMPT
            LDR     R0,=PROMPT               ;Print the prompt
			MOVS    R1,#MAX_STRING 
		    BL      PutStringSB
			
            BL      GetChar                  ;Get the input prompt                   
			BL      PutChar
			
			;capitalizing the letters
			CMP     R0,#'a'           
		    BLO     CHAR_CHECK
			
			CMP     R0,#'z'
			BHI     CHAR_CHECK
			SUBS    R0,R0,#'a'            ;removing the ascii of small letter
			ADDS    R0,R0,#'A'            ;putting the ascii of the capital letter 
			;************************
			
CHAR_CHECK	                              ;check if a valid character is input 		
			CMP     R0,#'G'
			BEQ     G_COMMAND
			
			CMP     R0,#'I'
			BEQ     I_COMMAND
			
			CMP     R0,#'L'
			BEQ     L_COMMAND
			
			CMP     R0,#'P'
			BEQ     P_COMMAND
			B       PUT_PROMPT            ;if the input is invalid, put the prompt again.
		
G_COMMAND						   		    
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			MOVS    R0,#'<'               ;output '<' to screen
			BL      PutChar
			
			LDR     R0,=StringBuffer
			MOVS    R1,#MAX_STRING
			
			BL      GetStringSB
			
			MOVS    R0,#' ' 
            BL      AdvanceCursor
    
			B       PUT_PROMPT
			
I_COMMAND
			
			LDR     R0,=StringBuffer 
 			MOVS    R1,#NULL
			STR     R1,[R0,#0]
			
			MOVS    R0,#' '
			BL      AdvanceCursor
			
			B       PUT_PROMPT
L_COMMAND
            BL      AdvanceCursor
			
			LDR     R0, =LENGTH                 ;print "Length: " to the screen
			BL      PutStringSB
			
			LDR     R0, =StringBuffer           ;get the lenth of the string
			MOVS    R1, #MAX_STRING             ;
			BL      LengthStringSB              ;provided in library 
			
			BL      PutNumU                     ;in decimal numbers
 
            MOVS    R0,#' '
			BL      AdvanceCursor
			
			B       PUT_PROMPT
P_COMMAND
            BL      AdvanceCursor
			
			MOVS    R0,#'>'                     ;output '>' to screen
            BL      PutChar
			
			LDR     R0,=StringBuffer
			BL      PutStringSB
			
			MOVS    R0,#'>'
			BL      PutChar
			
			MOVS    R0,#' '
			BL      AdvanceCursor
			
			B       PUT_PROMPT

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
				 
;************************************************************************			 
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
				
;************************************************************************
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
				
;************************************************************************
GetStringSB    PROC {R1-R14}
;Prevents overrun of the buffer capacity and adds Null Termination upon 
; pressing "Enter" key.
;R0 = memory location to store string
;R1 = Buffer capacity

		PUSH      {R0, R1, R2, R3, LR}
		MOVS      R2, #0                     ;Initalize string offset to zero
		MOVS      R3, R0 					 ;Save the character input 	 
INPUT
          
        BL      GetChar                       ;use GetChar to get the next character
											  ;in the string
											  
		CMP     R0, #CR                       ;check for carrige return
		BEQ     END_GetStringSB
		
		CMP     R1, #1                        ;check for end of string
        BEQ     INPUT
			                                   
		BL      PutChar                       ;use PutChar to echo to terminal
		
		STRB    R0, [R3, R2]                  ;String[i] = input char
		
        SUBS    R1, R1, #1                    ;Decrement number of characters left to read
	
		CMP     R0, #BS                       ;Check if backspace is typed
		BEQ     BS_Input

		ADDS	R2, R2, #1                    ;Add offset index for string			
		
        B       INPUT

BS_Input 
		CMP    R2, #0
		BEQ    INPUT
		SUBS   R2, R2, #1                     ;Decrease the offset
		B      INPUT
		
END_GetStringSB
		
		MOVS    R0, #0                        ;null termination
		STRB    R0, [R3, R2]
		
		POP    {R0, R1, R2, R3, PC}           ;nested subroutine
            
        ENDP
;************************************************************************

PutStringSB    PROC {R0-R14}
;Prevents overrun of the buffer capacity, displays a null terminated string
; to the terminal screen
;R0 = memory location of string to print
;R1 = Buffer capacity 
;R2 = Address of String Buffer

		PUSH   {R0-R2, LR}                     ;register retention for nested subroutine

		CMP    R1, #0                          ;If all characters have been processed
        BEQ    END_PutStringSB                 ;End subroutine execution
		ADDS   R1,R1,R0
		MOVS   R2, R0                          ;save R0 to R2 
READ_CHAR
        LDRB   R0,[R2,#0]
		CMP    R0,#NULL
		BEQ    END_PutStringSB
		
		BL     PutChar                         ;Echo character to the terminal
		
		ADDS    R2, R2, #1                     ;point to next value
		
		CMP     R2,R1
		BNE     READ_CHAR
		
END_PutStringSB
		POP {R0-R2, PC}                         ;nested subroutine
		ENDP
			
;************************************************************************	

PutNumU    PROC {R0-R14} 
;Display text decimal representation of unsigned word values.	
;Continuously Divide R0 value by 10
;and print the remainder
		
		PUSH {R0, R1, R2, LR}                   ;register retention for nested subroutine

		MOVS R2, #0                             ;Initalize Array offset to Zero
		
DIV10
		
		CMP R0, #10                             ;check if number is smaller than 10
		BLT END_PutNumU                         
		
		;Move dividend to R1, set divisor to 10
		MOVS R1, R0
		MOVS R0, #10
		
		;R1 / R0 = R0 Remainder R1
		BL DIVU
		
		;Print remainder stored in R1
		PUSH {R0}
		LDR R0, =StringReversal
		
		STRB R1, [R0, R2]
		ADDS R2, R2, #1
		
		POP {R0}
		
		;repeat until num is no longer divisible by 10
		B DIV10

END_PutNumU

		ADDS R0, R0, #'0'                        ;Convert to ASCII Value
		BL PutChar
		
		SUBS R2, R2, #1                          ;decrement string array
		
PRINT_CHAR		
 
		LDR R0, =StringReversal                  ;Iterate over array and print
		
		CMP R2, #0
		BLT END_PUTNUM
		
		LDRB R1, [R0, R2]
		MOVS R0, R1
		
		ADDS R0, R0, #'0'                        ;Convert to ASCII Character and Print
		BL PutChar
		
		SUBS R2, R2, #1
	
		B PRINT_CHAR
		
END_PUTNUM
		POP {R0, R1, R2, PC}                    ;restore previous values and get back to subroutine.
		ENDP
;****************************************************************

DIVU        PROC    {R2-R14}           
;****************************************************************
; Performs the division operation upon R1 by dividing it from R0
; and returning the Quotient and Remainder in R0 and R1 
; respectively. If Division by 0 is top be performed, R0 and R1 
; do not change their values, instead C bit is set.
;
; R0 rem R1 = R1 / R0 
;****************************************************************
            PUSH     {R2-R3}                   ;Temporary Registers  
            CMP      R0, #0                    ;Check for division by 0
            BEQ      DIV_BY_0                  
            CMP      R1, #0                    ;Check for division of 0			
            BEQ      DIV_OF_0                  
								               
			MOVS     R2, R0                    ;Temporarily storing the dividend
			MOVS     R0, #0                    ;Initializing the quotient
								               
While       CMP      R1,R2                     ;check for Dividend >= Divisor
            BLO      DIV_END                   
            SUBS     R1,R1,R2                  ;Dividend -= Divisor
            ADDS	 R0,R0,#1	               ;Quotient++
			B        While                     
								               
DIV_END     MRS      R2, APSR                  ;Clear flags.
            MOVS     R3, #0x20                 ;Create Mask
			LSLS     R3,R3,#24                 ;Shift to MSB
			BICS     R2,R3                     ;
			MSR      APSR, R2                  
								               
DIV_DONE    POP      {R2-R3}                    ;Store Temporary Registers.
            BX       LR                        
								               
DIV_OF_0    MOVS     R0, #0                     ;Set Quotient = 0
            MOVS     R1, #0                     ;Set Remainder = 0
			B        DIV_END                   
								               
DIV_BY_0    MRS      R2, APSR                   ;Clear all flags
            MOVS     R3, #0x20                  ;Mask
			LSLS     R3,R3,#24                 
			ORRS     R2,R3                     
			MSR      APSR,R2                    ;Set C Flag
			B        DIV_DONE                  
			ENDP                               
;****************************************************************

AdvanceCursor    PROC {R0-R14}
;Echo the character with a carriage return, line feed and move the 
;cursor to the next line.
                 PUSH     {R0,LR}               ;Register retention, and nested subroutine
				 ;BL       PutChar               ;Echo character
				 
				 MOVS     R0,#CR
				 BL       PutChar
				 MOVS     R0,#LF
				 BL       PutChar

                 POP	  {R0,PC}               ;Register retention, and exiting subroutine
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
PROMPT		DCB      "Type a string command (g, i, l, p): ", NULL
            ALIGN
LENGTH		DCB      "Length: ", NULL
;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
StringBuffer 		SPACE     MAX_STRING
StringReversal		SPACE     MAX_STRING	
;>>>>>   end variables here <<<<<
            ALIGN
            END
