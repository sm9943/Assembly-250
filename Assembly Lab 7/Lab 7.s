		TTL Exercise 7 Circular FIFO Queue Operations
;****************************************************************
;Assembly program to handle a queue of a capacity of 4 items. 
; The also program updates the user about the address of the  
; In-pointer and the out pointer of with every queue operation.  
;Name:  Shubhang Mehrotra
;Date:  03/11/2021
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
; Queue management record field offsets
IN_PTR      EQU   0
OUT_PTR     EQU   4
BUF_STRT    EQU   8
BUF_PAST    EQU   12
BUF_SIZE    EQU   16
NUM_ENQD    EQU   17
	
; Queue structure sizes
Q_BUF_SZ    EQU   4  	;Queue contents (80 in pdf file?)
Q_REC_SZ    EQU   18  	;Queue management record

PutNumUB_MASK   EQU   0xFF
C_MASK			EQU	  0x20
C_SHIFT 		EQU	  24	
	

;from Lab 6
MAX_STRING	EQU   79
	
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

;****************************************************************
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
Reset_Handler  PROC  {}
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL05 system startup with 48-MHz system clock
            BL      Startup
			BL      Init_UART0_Polling
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<

			;Load input params to initalize queue structure
			LDR 	R0, =QBuffer
			LDR 	R1, =QRecord
			MOVS	R2, #Q_BUF_SZ
		
			;Initalize Queue structure
			BL		InitQueue
			
PRINT_PROMPT

			;Load static prompt string address
			LDR  R0, =Prompt
			MOVS R1, #MAX_STRING
			;Print prompt string
			BL PutStringSB	
PROMPT			
			;Get input prompt
			BL GetChar		
			;echo prompt
			BL PutChar		
			
			;capitalizing the letters
			CMP     R0,#'a'           
		        BLO     CHAR_CHECK
			
			CMP     R0,#'z'
			BHI     CHAR_CHECK
			SUBS    R0,R0,#'a'            ;removing the ascii of small letter
			ADDS    R0,R0,#'A'            ;putting the ascii of the capital letter 
			;************************
			
CHAR_CHECK	                              ;check if a valid character is input 		
			CMP     R0,#'D'
			BEQ     D_COMMAND
			
			CMP     R0,#'E'
			BEQ     E_COMMAND
			
			CMP     R0,#'H'
			BEQ     H_COMMAND
			
			CMP     R0,#'P'
			BEQ     P_COMMAND
			
			CMP     R0,#'S'
			BEQ     S_COMMAND
			B       PROMPT          ;if the input is invalid, put the prompt again.
			
;-------------------------------------------			
D_COMMAND
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			;Load input params
			LDR		R0, =QBuffer
			LDR     R1, =QRecord
			MOVS	R2,	#Q_BUF_SZ
			
			;call subroutine
			BL		Dequeue
			
			;check for failure
			BCS		DQ_Fail
			
			;Print value retrieved from queue
			BL		PutChar
			MOVS	        R0, #":"
			BL		PutChar
			
			LDR     R0, =QRecord
			BL      DeQueueStatus
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			;return to initial prompt
			B       PRINT_PROMPT

DQ_Fail		
			;echo failure and restart
			LDR     R0, =Failure
			BL      PutStringSB
			
			LDR     R0, =QRecord
			BL      QueueStatus
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			;return to initial prompt
			B       PRINT_PROMPT	
;-------------------------------------------
E_COMMAND 	
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			;Prompt user
			LDR		R0, =EnqueuePrompt
			BL		PutStringSB
			
			;Load input params
			LDR		R0, =QBuffer
			LDR     R1, =QRecord
			MOVS	R2,	#Q_BUF_SZ			

			;grab input
			BL		GetChar
			;echo
			BL      PutChar
			;add to queue
			BL		Enqueue
			
			;check for failure
			BCS 	EQ_Failure
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			LDR		R0, =Success
			BL		PutStringSB
			
			LDR     R0, =QRecord
			BL		QueueStatus
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			;return to initial prompt
			B		PRINT_PROMPT
			
EQ_Failure
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			LDR     R0, =Failure
			BL      PutStringSB
			
			LDR		R0, =QRecord
			BL		QueueStatus

			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			;return to initial prompt
			B		PRINT_PROMPT
;-------------------------------------------
H_COMMAND
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf

			LDR		R0, =HelpString
			BL		PutStringSB
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			;return to initial prompt
			B		PRINT_PROMPT
;-------------------------------------------
S_COMMAND
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			LDR     R0, =Status
			BL		PutStringSB
			
			LDR		R0, =QRecord
			BL		QueueStatus
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			;return to initial prompt
			B		PRINT_PROMPT
;-------------------------------------------
P_COMMAND
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf
			
			;print delimiter
			PUSH    {R0-R4}
			MOVS	R0, #'>'
			BL		PutChar
			
			;Load Input Params
			LDR		R1, =QRecord
			LDR		R0, =QBuffer
			
			LDRB	R2, [R1, #NUM_ENQD]
			
			LDR     R3, [R1, #OUT_PTR]  	
P_NEXT			
			;end of buffer reached
			CMP     R2, #0
			BEQ		P_EXIT
			
			;print queue character
			LDRB 	R4, [R3, #0]
			
			;Move char to R0 to print
			PUSH 	{R0}
			MOVS 	R0, R4
			BL 		PutChar
			POP 	{R0}
			
			;Decrement num_enqd
			SUBS	R2, R2, #1
			
			;Increment the out_ptr
			ADDS	R3, R3, #1	
			
			;Compare OUT_PTR to BUF_PAST
			;If out_ptr >= BUF_PAST, wrap the queue around
			LDR 	R4, [R1, #BUF_PAST]
			CMP 	R3, R4
			BEQ 	P_WRAP
			
			B 		P_NEXT

P_WRAP
			;Adjust out_ptr to equal buf_strt
			;Thus wrapping around the circular queue
			LDR 	R3, [R1, #BUF_STRT]
			B		P_NEXT
			
P_EXIT       
			;print delimiter
			MOVS	R0, #'<'
			BL		PutChar
			
			BL      AdvanceCursor         ;Output character on screen, with a cr and lf

			
			POP     {R0- R4}
			B		P_END

P_END		;return to initial prompt
			B       PRINT_PROMPT
			
			
		
;-------------------------------------------

;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP
;>>>>> begin subroutine code <<<<<

QueueStatus
;QueueStatus: Print the inpointer, outpointer, and
;number of elements that are enqueued in the current queue.

;Inputs:
	;R0 = address of queue record structure
;Outputs
	;N/A
;-------------------------------------------
	PUSH 	{R0-R3, LR}
	
	LDR 	R1, [R0, #IN_PTR]
	LDR 	R2, [R0, #OUT_PTR]
	LDRB 	R3, [R0, #NUM_ENQD]
	
	;Print chars '   In='
	LDR 	R0, =Spaces
	BL 		PutStringSB
	LDR 	R0, =In
	BL 		PutStringSB
	
	;Print in_ptr address of queue
	MOVS 	R0, R1
	BL 		PutNumHex
	
	;Print chars '   Out='
	LDR 	R0, =Spaces
	BL 		PutStringSB
	LDR 	R0, =Out
	BL 		PutStringSB
	
	;Print out+ptr address of queue
	MOVS 	R0, R2
	BL 		PutNumHex
	
	;Print chars '   Num='
	LDR 	R0, =Spaces
	BL 		PutStringSB
	LDR 	R0, =Num
	BL 		PutStringSB
	
	;Print number of elements currently enqueued
	MOVS 	R0, R3
	BL 		PutNumU
	
	;register retention, 
	POP 	{R0-R3, PC}	
;**************************************

DeQueueStatus
;DeQueueStatus: Print the inpointer, outpointer, and
;number of elements that are enqueued in the current queue.

;Inputs:
	;R0 = address of queue record structure
;Outputs
	;N/A
;-------------------------------------------
	PUSH 	{R0-R3, LR}
	
	LDR 	R1, [R0, #IN_PTR]
	LDR 	R2, [R0, #OUT_PTR]
	LDRB 	R3, [R0, #NUM_ENQD]
	
	;Print chars '   In='
	LDR 	R0, =Spaces_DQ
	BL 		PutStringSB
	LDR 	R0, =In
	BL 		PutStringSB
	
	;Print in_ptr address of queue
	MOVS 	R0, R1
	BL 		PutNumHex
	
	;Print chars '   Out='
	LDR 	R0, =Spaces
	BL 		PutStringSB
	LDR 	R0, =Out
	BL 		PutStringSB
	
	;Print out+ptr address of queue
	MOVS 	R0, R2
	BL 		PutNumHex
	
	;Print chars '   Num='
	LDR 	R0, =Spaces
	BL 		PutStringSB
	LDR 	R0, =Num
	BL 		PutStringSB
	
	;Print number of elements currently enqueued
	MOVS 	R0, R3
	BL 		PutNumU
	
	;register retention, 
	POP 	{R0-R3, PC}	
;**************************************

InitQueue   PROC   {R0-R14}
;InitQueue: Initalize Circular FIFO Queue Structure
;Inputs:
;	R0 - Memory location of queue buffer
;	R1 - Address to place Queue record structure
;	R2 - Size of queue structure (character capacity)
;Outputs:
;	none
;--------------------------------------------
		PUSH    {R0-R2}
		
		
		;Store memory address of front of queue
		;Into IN_PTR position of the buffer
		STR 	R0, [R1, #IN_PTR]

		;Store same memory address for OUT_PTR
		;position in the buffer since queue is empty
		STR 	R0, [R1, #OUT_PTR]

		;Store same memory address in BUF_STRT for initalization
		STR 	R0, [R1, #BUF_STRT]

		;Store BUF_PAST in last slot of buffer
		ADDS    R0, R0, R2
		STR 	R0, [R1, #BUF_PAST]

		;Store BUF_SIZE with size in R2
		STRB 	R2, [R1, #BUF_SIZE]
		
		;Initalize NUM_ENQD to zero and 
		;store in 6th slot of buffer
		MOVS 	R0, #0
		STRB 	R0, [R1, #NUM_ENQD]
		POP		{R0-R2}
		BX		LR
		ENDP
;**************************************    

Dequeue		PROC   {R1-R14}
;Dequeue: Remove an element from the circular FIFO Queue
;Inputs:
;	R1 - Address of Queue record structure
;Outputs:
;	R0 - Character that has been dequeued
;	PSR C flag : Failure - C = 1
;				 Success - C = 0 
;--------------------------------------------
			PUSH 	{R1-R4}
			
			;If the number enqueued is 0, 
			;Set failure PSR flag
			LDRB 	R3, [R1, #NUM_ENQD]
			CMP 	R3, #0
			BLE 	DEQUEUE_FAILURE
			
			LDR  	R4, [R1, #OUT_PTR]
			
			;Remove the item from the queue
			;And place in R0
			LDRB 	R0, [R4, #0]
			
			;Decrement number of enqueued elements
			;And store info back in buffer
			LDRB 	R3, [R1, #NUM_ENQD]
			SUBS 	R3, R3, #1
			STRB 	R3, [R1, #NUM_ENQD] 
			
			
			;Increment location of out_pointer
			ADDS 	R4, R4, #1
			
			
			;Compare OUT_PTR to BUF_PAST
			;If out_ptr >= BUF_PAST, wrap the queue around
			LDR 	R3, [R1, #BUF_PAST]
			CMP 	R3, R4
			BEQ 	WRAP_BUFFER
			
			STR 	R4, [R1, #OUT_PTR] 
			B 		DEQUEUE_CLEAR_PSR
			
WRAP_BUFFER
			;Adjust out_ptr to equal buf_strt
			;Thus wrapping around the circular queue
			LDR 	R3, [R1, #BUF_STRT]
			STR 	R3, [R1, #OUT_PTR]

DEQUEUE_CLEAR_PSR
			;Clear the PSR C flag
			MRS 	R1, APSR
			MOVS 	R3, #C_MASK
			LSLS 	R1, R1, #C_SHIFT
			BICS 	R1, R1, R3
			MSR		APSR, R1
			
			;Successfully end the operation
			B END_DEQUEUE
			
DEQUEUE_FAILURE
			;Set PSR C flag to 1
			MRS 	R1, APSR
			MOVS 	R3, #C_MASK  
			LSLS 	R3, R3, #C_SHIFT 
			ORRS 	R1, R1, R3
			MSR 	APSR, R1
			
END_DEQUEUE
			POP 	{R1-R4}
			BX		LR
			ENDP
;**************************************   

Enqueue		PROC   {R0-R14}
;Enqueue: Add an element to the circular FIFO Queue
;Inputs:
	;R0 - Character to enqueue
	;R1 - Address of the Queue record
;Outputs:
	;PSR C flag (failure if C = 1, C = 0 otherwise.)
;--------------------------------------------'

			PUSH {R2, R3, R4}
			
			;If num_enqd >= size of the queue
			;Then set PSR C flag to 1 indicating
			;the error that an element was not inserted
			;into a full queue
			
			LDRB 	R3, [R1, #NUM_ENQD]
			LDRB 	R4, [R1, #BUF_SIZE]
			CMP 	R3, R4
			BGE 	QUEUE_FULL
			B 		BEGIN_ENQUEUE
			
QUEUE_FULL
			;Set PSR C flag to 1
			MRS 	R1, APSR
			MOVS 	R3, #C_MASK
			LSLS 	R3, R3, #C_SHIFT
			ORRS 	R1, R1, R3
			MSR 	APSR, R1
			B 		END_ENQUEUE
			
BEGIN_ENQUEUE
			
			;Load mem address of in_ptr
			;and then store the value to be enqueued
			;into the value at that memory address
			LDR 	R3, [R1, #IN_PTR]
			STRB 	R0, [R3, #0]
			
			;Increment value of in_ptr by 1, 1 value past
			;The queue item. Then store back in IN_PTR
			
			;check for end of buffer first,
			
			ADDS 	R3, R3, #1
			STR 	R3, [R1, #IN_PTR]
			
			;Increment number of enqueued elements
			LDRB 	R3, [R1, #NUM_ENQD]
			ADDS 	R3, R3, #1
			STRB 	R3, [R1, #NUM_ENQD]
			
			;If IN_PTR is >= BUF_PAST
			;Loop around and adjust inPtr to beginning of
			;the queue buffer
			LDR 	R3, [R1, #IN_PTR]
			LDR 	R4, [R1, #BUF_PAST]
			
			CMP	 	R3, R4
			BGE 	WRAP_ENQUEUE
			
			;Clear the PSR C flag confirming successful result
			MRS 	R2, APSR
			MOVS 	R3, #C_MASK
			LSLS 	R2, R2, #C_SHIFT
			BICS 	R2, R2, R3
			MSR		APSR, R2
			
			B 		END_ENQUEUE
			
WRAP_ENQUEUE
			;Adjust in_ptr to beginning of queue buffer
			LDR 	R2, [R1, #BUF_STRT]
			STR 	R2, [R1, #IN_PTR]
			
			;Clear the PSR C flag confirming successful result
			MRS 	R2, APSR
			MOVS 	R3, #C_MASK
			LSLS	R2, R2, #C_SHIFT
			BICS 	R2, R2, R3
			MSR		APSR, R2
			
END_ENQUEUE
			
			POP 	{R2, R3, R4}
			BX		LR
			ENDP
;**************************************      

PutNumHex   PROC   {R0-R14}
;Print hex representation of a value.
;Inputs:
;	R0 - Value to print to the screen
;Outputs:
;	none
;--------------------------------------------
        PUSH {R2-R4, LR}
    
        MOVS 	R2, #32

HEX_PRINT_LOOP

        ;Iterate 8 times for each digit stored in a register
        CMP 	R2, #0
        BLT 	END_PRINT_HEX
        
        ;Shift current nibble to print to
        ;the rightmost value of register
        MOVS 	R3, R0
		MOVS 	R4, #0x0F
		LSRS 	R3, R2
		
		ANDS 	R4, R4, R3
		
        ;Convert to appropriate ASCII value
        CMP 	R4, #10
        BGE 	PRINT_LETTER
        
        ;If 0-9 should be printed, add ASCII '0' val
        ADDS 	R4, #'0'
        B 		PRINT_HX
        
PRINT_LETTER
        
        ;If A-F should be printed, Add ASCII '55'
        ;To convert to capital letter value
        ADDS R4, R4, #55
        
PRINT_HX
        ;Print ASCII value to the screen
        ;Make sure not to destroy vlue in R0!
        PUSH 	{R0}
        MOVS	R0, R4
        BL 		PutChar
        POP 	{R0}
        
        ;Reset value in R3 and increment loop counter
        MOVS 	R4, #0
        SUBS 	R2, R2, #4
        B 		HEX_PRINT_LOOP
        
END_PRINT_HEX
       
        POP 	{R2-R4, PC}
		ENDP	
	
;**************************************      

PutNumUB    PROC   {R0-R14}
;Print binary representation of the 
; unisgned byte value in R0
;Inputs:
;	R0 - Value to print to the screen
;Outputs:
;	none
;--------------------------------------------		
		PUSH 	{R0}
		
		LDR   	R0,[R0,#0]
		MOVS  	R1, #PutNumUB_MASK  
		ANDS  	R0, R0, R1
		BL 		PutNumU		
	
		POP 	{R0}
			
			ENDP
;**************************************     
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
            MOVS     R3, #C_MASK               ;Create Mask
			LSLS     R3,R3,#C_SHIFT            ;Shift to MSB
			BICS     R2,R3                     ;
			MSR      APSR, R2                  
								               
DIV_DONE    POP      {R2-R3}                    ;Store Temporary Registers.
            BX       LR                        
								               
DIV_OF_0    MOVS     R0, #0                     ;Set Quotient = 0
            MOVS     R1, #0                     ;Set Remainder = 0
			B        DIV_END                   
								               
DIV_BY_0    MRS      R2, APSR                   ;Clear all flags
            MOVS     R3, #C_MASK                ;Mask
			LSLS     R3,R3,#C_SHIFT                
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
Prompt				DCB		"Type a queue command (D, E, H, P, S): ", NULL
					ALIGN
EnqueuePrompt 		DCB		"Character to enqueue: ", NULL
					ALIGN
HelpString			DCB		"D (dequeue), E (enqueue), H (help}, P (print), S (status)", NULL
					ALIGN
Success				DCB 	"Success: ", NULL
					ALIGN
Failure				DCB 	"Failure: ", NULL
					ALIGN
Status				DCB 	"Status: ", NULL
					ALIGN
In					DCB 	"In=0x", NULL
					ALIGN
Out					DCB 	"Out=0x", NULL
					ALIGN
Num					DCB 	"Num= ", NULL
					ALIGN
Spaces				DCB 	"   ", NULL
					ALIGN
Spaces_DQ			DCB		"          ", NULL
					ALIGN
;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
 ;Queue structures 
QBuffer   SPACE  Q_BUF_SZ  ;Queue contents 
QRecord   SPACE  Q_REC_SZ  ;Queue management record 
	
;from lab 6	
StringBuffer 		SPACE     MAX_STRING
StringReversal		SPACE     MAX_STRING		
;>>>>>   end variables here <<<<<
            ALIGN
            END