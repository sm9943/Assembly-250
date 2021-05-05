/***************************************************************/
/* Module of functions to support UART0 I/O with polling       */
/* R. W. Melton                                                */
/* 9/13/2020                                                   */
/***************************************************************/

#include <MKL05Z4.h>
#include "UART0_Polling.h"

char GetChar (void) {
/***************************************************************/
/* Gets a character from UART0 using polling.                  */
/* Waits until UART0 RDRF and then gets a character from       */
/* UART0 DR.                                                   */
/***************************************************************/
  CLR_RX_OR;  /* Optional clear Rx overrun */
  while (!(UART0->S1 & UART0_S1_RDRF_MASK));
  return (UART0->D);
}

void Init_UART0_Polling (void) {
/***************************************************************/
/* Initializes UART0 for 9600 baud and 8N1 format              */
/***************************************************************/
  /* Select MCGFLLCLK as UART0 clock source */
  SIM->SOPT2 &= ~SIM_SOPT2_UART0SRC_MASK;
  SIM->SOPT2 |= SIM_SOPT2_UART0SRC_MCGFLLCLK;
  /* Set UART0 for external connection */
  SIM->SOPT5 &= ~SIM_SOPT5_UART0_EXTERN_MASK_CLEAR;
  /* Enable UART0 module clock */
  SIM->SCGC4 |= SIM_SCGC4_UART0_MASK;
  /* Some OpenSDA applications provide a virtual serial port */
  /* through the OpenSDA USB connection using PTB1 and PTB2  */
  /* Enable PORT B module clock */
  SIM->SCGC5 |= SIM_SCGC5_PORTB_MASK;
  /* Select PORT B Pin 2 (D0) for UART0 RX */
  PORTB->PCR[2] = PORT_PCR_SET_PTB2_UART0_RX;
  /* Select PORT B Pin 1 (D1) for UART0 TX */
  PORTB->PCR[1] = PORT_PCR_SET_PTB1_UART0_TX;
  /* Set for 9600 baud from 48MHz FLL clock */
  UART0->C2 &= ~UART0_C2_T_R;  /* disable UART0 */
  UART0->BDH = UART0_BDH_9600;
  UART0->BDL = UART0_BDL_9600;
  UART0->C1 = UART0_C1_8N1;
  UART0->C3 = UART0_C3_NO_TXINV;
  UART0->C4 = UART0_C4_NO_MATCH_OSR_16;
  UART0->C5 = UART0_C5_NO_DMA_SSR_SYNC;
  UART0->S1 = UART0_S1_CLEAR_FLAGS;
  UART0->S2 = UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS;
  UART0->C2 = UART0_C2_T_R;  /* enable UART0 */
}

void PutChar (char Character) {
/***************************************************************/
/* Puts Character to UART0 using polling.                      */
/* Waits until UART0 TDRE and then puts Character into         */
/* UART0 DR.                                                   */
/***************************************************************/
  while (!(UART0->S1 & UART0_S1_TDRE_MASK));
  UART0->D = Character;
}
