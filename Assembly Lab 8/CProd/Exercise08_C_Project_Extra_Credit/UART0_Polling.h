/***************************************************************/
/* Definitions for module to support UART0 I/O with polling    */
/* R. W. Melton                                                */
/* 9/13/2020                                                   */
/***************************************************************/

/**************************************************************/
/* Macro constants                                            */
/**************************************************************/
/*------------------------------------------------------------*/
/* PORTx_PCRn (Port x pin control register n [for pin n])     */
/* 10-08:MUX=Pin mux control (select 0 to 8)                  */
/*------------------------------------------------------------*/
#define PORT_PCR_MUX_SELECT_2_MASK (2u << PORT_PCR_MUX_SHIFT)
/*------------------------------------------------------------*/
/* Port B                                                     */
/*------------------------------------------------------------*/
#define PORT_PCR_SET_PTB2_UART0_RX (PORT_PCR_ISF_MASK | \
                                    PORT_PCR_MUX_SELECT_2_MASK)
#define PORT_PCR_SET_PTB1_UART0_TX (PORT_PCR_ISF_MASK | \
                                    PORT_PCR_MUX_SELECT_2_MASK)
/*------------------------------------------------------------*/
/* SIM_SCGC4                                                  */
/* 1->10:UART0 clock gate control (enabled)                   */
/*------------------------------------------------------------*/
/* Use provided SIM_SCGC4_UART0_MASK                          */
/*------------------------------------------------------------*/
/* SIM_SCGC5                                                  */
/* 1->09:Port A clock gate control (enabled)                  */
/*------------------------------------------------------------*/
/* Use provided SIM_SCGC5_PORTA_MASK                          */
/*------------------------------------------------------------*/
/* SIM_SOPT2                                                  */
/* 01=27-26:UART0SRC=UART0 clock source select                */
/*          PLLFLLSEL determines MCGFLLCLK' or MCGPLLCLK/2    */
/*------------------------------------------------------------*/
#define SIM_SOPT2_UART0SRC_MCGFLLCLK \
                                (1u << SIM_SOPT2_UART0SRC_SHIFT)
/*------------------------------------------------------------*/
/* SIM_SOPT5                                                  */
/*  0->   16:UART0 open drain enable (disabled)               */
/*  0->   02:UART0 receive data select (UART0_RX)             */
/* 00->01-00:UART0 transmit data select source (UART0_TX)     */
/*------------------------------------------------------------*/
#define SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  \
                                  (SIM_SOPT5_UART0ODE_MASK | \
                                   SIM_SOPT5_UART0RXSRC_MASK | \
                                   SIM_SOPT5_UART0TXSRC_MASK)
/*------------------------------------------------------------*/
/* UART0_BDH                                                  */
/*     0->  7:LIN break detect IE (disabled)                  */
/*     0->  6:RxD input active edge IE (disabled)             */
/*     0->  5:Stop bit number select (1)                      */
/* 00001->4-0:SBR[12:0] (MCGFLLCLK / [9600 * (OSR + 1)])      */
/* MCGFLLCLK is 47972352 Hz ~=~ 48 MHz                        */
/* SBR ~=~ 48 MHz / (9600 * 16) = 312.5 --> 312               */
/* SBR = 47972352 / (9600 * 16) = 312.32 --> 312 = 0x138      */
/*------------------------------------------------------------*/
#define UART0_BDH_9600  (0x01u)
/*------------------------------------------------------------*/
/* UART0_BDL                                                  */
/* 26->7-0:SBR[7:0] (MCGFLLCLK / [9600 * (OSR + 1)])          */
/* MCGFLLCLK is 47972352 Hz ~=~ 48 MHz                        */
/* SBR ~=~ 48 MHz / (9600 * 16) = 312.5 --> 312               */
/* SBR = 47972352 / (9600 * 16) = 312.32 --> 312 = 0x138      */
/*------------------------------------------------------------*/
#define UART0_BDL_9600  (0x38u)
/*------------------------------------------------------------*/
/* UART0_C1                                                   */
/* 0-->7:LOOPS=loops select (normal)                          */
/* 0-->6:DOZEEN=doeze enable (disabled)                       */
/* 0-->5:RSRC=receiver source select                          */
/*            (internal--no effect LOOPS=0)                   */
/* 0-->4:M=9- or 8-bit mode select                            */
/*        (1 start, 8 data [lsb first], 1 stop)               */
/* 0-->3:WAKE=receiver wakeup method select (idle)            */
/* 0-->2:IDLE=idle line type select                           */
/*           (idle begins after start bit)                    */
/* 0-->1:PE=parity enable (disabled)                          */
/* 0-->0:PT=parity type (even parity--no effect PE=0)         */
/*------------------------------------------------------------*/
#define UART0_C1_8N1  (0x00)
/*------------------------------------------------------------*/
/*UART0_C2                                                    */
/*0-->7:TIE=transmit IE for TDRE (disabled)                   */
/*0-->6:TCIE=transmission complete IE for TC (disabled)       */
/*0-->5:RIE=receiver IE for RDRF (disabled)                   */
/*0-->4:ILIE=idle line IE for IDLE (disabled)                 */
/*1-->3:TE=transmitter enable (enabled)                       */
/*1-->2:RE=receiver enable (enabled)                          */
/*0-->1:RWU=receiver wakeup control (normal)                  */
/*0-->0:SBK=send break (disabled, normal)                     */
/*------------------------------------------------------------*/
#define UART0_C2_T_R  (UART0_C2_TE_MASK | UART0_C2_RE_MASK)
/*------------------------------------------------------------*/
/* UART0_C3                                                   */
/* 0-->7:R8T9=9th data bit for receiver (not used M=0)        */
/*            10th data bit for transmitter (not used M10=0)  */
/* 0-->6:R9T8=9th data bit for transmitter (not used M=0)     */
/*            10th data bit for receiver (not used M10=0)     */
/* 0-->5:TXDIR=UART_TX pin direction in single-wire mode      */
/*             (no effect LOOPS=0)                            */
/* 0-->4:TXINV=transmit data inversion (not inverted)         */
/* 0-->3:ORIE=overrun IE for OR (disabled)                    */
/* 0-->2:NEIE=noise error IE for NF (disabled)                */
/* 0-->1:FEIE=framing error IE for FE (disabled)              */
/* 0-->0:PEIE=parity error IE for PF (disabled)               */
/*------------------------------------------------------------*/
#define UART0_C3_NO_TXINV  (0x00)
/*------------------------------------------------------------*/
/* UART0_C4                                                   */
/*     0-->  7:MAEN1=match address mode enable 1 (disabled)   */
/*     0-->  6:MAEN2=match address mode enable 2 (disabled)   */
/*     0-->  5:M10=10-bit mode select (not selected)          */
/* 01111-->4-0:OSR=over sampling ratio (16)                   */
/*                = 1 + OSR for 3 <= OSR <= 31                */
/*                = 16 for 0 <= OSR <= 2 (invalid values)     */
/*------------------------------------------------------------*/
#define UART0_C4_OSR_16  (0x0Fu)
#define UART0_C4_NO_MATCH_OSR_16  (UART0_C4_OSR_16)
/*------------------------------------------------------------*/
/* UART0_C5                                                   */
/*   0-->  7:TDMAE=transmitter DMA enable (disabled)          */
/*   0-->  6:Reserved; read-only; always 0                    */
/*   0-->  5:RDMAE=receiver full DMA enable (disabled)        */
/* 000-->4-2:Reserved; read-only; always 0                    */
/*   0-->  1:BOTHEDGE=both edge sampling (rising edge only)   */
/*   0-->  0:RESYNCDIS=resynchronization disable (enabled)    */
/*------------------------------------------------------------*/
#define UART0_C5_NO_DMA_SSR_SYNC  (0x00)
/*------------------------------------------------------------*/
/* UART0_S1                                                   */
/* 0-->7:TDRE=transmit data register empty flag; read-only    */
/* 0-->6:TC=transmission complete flag; read-only             */
/* 0-->5:RDRF=receive data register full flag; read-only      */
/* 1-->4:IDLE=idle line flag; write 1 to clear (clear)        */
/* 1-->3:OR=receiver overrun flag; write 1 to clear (clear)   */
/* 1-->2:NF=noise flag; write 1 to clear (clear)              */
/* 1-->1:FE=framing error flag; write 1 to clear (clear)      */
/* 1-->0:PF=parity error flag; write 1 to clear (clear)       */
/*------------------------------------------------------------*/
#define UART0_S1_CLEAR_FLAGS  (UART0_S1_IDLE_MASK | \
                               UART0_S1_OR_MASK | \
                               UART0_S1_NF_MASK | \
                               UART0_S1_FE_MASK | \
                               UART0_S1_PF_MASK)
/*------------------------------------------------------------*/
/* UART0_S2                                                   */
/* 1-->7:LBKDIF=LIN break detect interrupt flag (clear)       */
/*              write 1 to clear                              */
/* 1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)   */
/*               write 1 to clear                             */
/* 0-->5:(reserved); read-only; always 0                      */
/* 0-->4:RXINV=receive data inversion (disabled)              */
/* 0-->3:RWUID=receive wake-up idle detect                    */
/* 0-->2:BRK13=break character generation length (10)         */
/* 0-->1:LBKDE=LIN break detect enable (disabled)             */
/* 0-->0:RAF=receiver active flag; read-only                  */
/*------------------------------------------------------------*/
#define UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  ( \
                 UART0_S2_LBKDIF_MASK | UART0_S2_RXEDGIF_MASK)

/**************************************************************/
/* Macro functions                                            */
/**************************************************************/
/* Clear UART0 Rx overrun condition */
#define CLR_RX_OR (UART0->S1 = UART0_S1_OR_MASK)

char GetChar (void);
void Init_UART0_Polling (void);
void PutChar (char Character);
