/*********************************************************************/
/* C language code to control brightness of the Red LED on the 			 */
/* KL05Z board using PWM duty cycle moudlation											 */
/* Name:  Shubhang Mehrotra                                          */
/* Date:  04/26/2021                                                 */
/* Class:  CMPE 250                                                  */
/* Section:  01, Thursday 2 PM	                                     */
/*-------------------------------------------------------------------*/
/* Template:  R. W. Melton                                           */
/*            November 2, 2020                                       */
/*********************************************************************/
#include <MKL05Z4.h>
#include "Exercise11_C.h"

#define FALSE      (0)
#define TRUE       (1)

#define MAX_STRING (79u)

#define PWM_FREQ        (60u)
#define TPM_SOURCE_FREQ (47972352u)
#define TPM_PWM_PERIOD ((TPM_SOURCE_FREQ / (1 << TPM_SC_PS_VAL)) / \
                            PWM_FREQ)

#define LED_LEVELS (5u)

/* ADC0 */
#define ADC_MAX (0x3FFu)
#define ADC_VALUES (0x400u)
/* ------------------------------------------------------------------*/
/* ADC0_CFG1:  ADC0 configuration register 1                         */
/*  0-->31-8:(reserved):read-only:0                                  */
/*  1-->   7:ADLPC=ADC low-power configuration                       */
/* 10--> 6-5:ADIV=ADC clock divide select                            */
/*           Internal ADC clock = input clock / 2^ADIV               */
/*  1-->   4:ADLSMP=ADC long sample time configuration               */
/* 10--> 3-2:MODE=conversion mode selection                          */
/*           00=single-ended 8-bit conversion                        */
/*           01=single-ended 12-bit conversion                       */
/*           10=single-ended 10-bit conversion                       */
/*           11=(reserved) do not use this value                     */
/* 01--> 1-0:ADICLK=ADC input clock select                           */
/*           00=bus clock                                            */
/*           01=bus clock / 2                                        */
/*           10=alternate clock (ALTCLK)                             */
/*           11=asynchronous clock (ADACK)                           */
/* BUSCLK = CORECLK / 2 = FLLCLK / 2                                 */
/* FLLCLK is ~48 MHz                                                 */
/* FLLCLK is 47972352 Hz                                             */
/* BUSCLK is ~24 MHz                                                 */
/* BUSCLK is 23986176 Hz                                             */
/* ADCinCLK is BUSCLK / 2 = ~12 MHz                                  */
/* BUSCLK is 11993088 Hz                                             */
/* ADCCLK is ADCinCLK / 4 = ~3 MHz                                   */
/* ADCCLK is 2998272 Hz                                              */
#define ADC0_CFG1_ADIV_BY2 (2u)
#define ADC0_CFG1_MODE_SGL10 (2u)
#define ADC0_CFG1_ADICLK_BUSCLK_DIV2 (1u)
#define ADC0_CFG1_LP_LONG_SGL10_3MHZ (ADC_CFG1_ADLPC_MASK | \
              (ADC0_CFG1_ADIV_BY2 << ADC_CFG1_ADIV_SHIFT) | \
                                     ADC_CFG1_ADLSMP_MASK | \
            (ADC0_CFG1_MODE_SGL10 << ADC_CFG1_MODE_SHIFT) | \
                               ADC0_CFG1_ADICLK_BUSCLK_DIV2)
/*-------------------------------------------------------------*/
/* ADC0_CFG2:  ADC0 configuration register 2                   */
/*  0-->31-8:(reserved):read-only:0                            */
/*  0--> 7-5:(reserved):read-only:0                            */
/*  0-->   4:MUXSEL=ADC mux select:  A channel                 */
/*  0-->   3:ADACKEN=ADC asynchronous clock output enable      */
/*  0-->   2:ADHSC=ADC high-speed configuration:  normal       */
/* 00--> 1-0:ADLSTS=ADC long sample time select (ADK cycles)   */
/*           default longest sample time:  24 total ADK cycles */
#define ADC0_CFG2_CHAN_A_NORMAL_LONG (0x00u)
/*---------------------------------------------------------   */
/* ADC0_SC1:  ADC0 channel status and control register 1      */
/*     0-->31-8:(reserved):read-only:0                        */
/*     0-->   7:COCO=conversion complete flag (read-only)     */
/*     0-->   6:AIEN=ADC interrupt enabled                    */
/*     0-->   5:(reserved):should not be changed              */
/* 00101--> 4-0:ADCH=ADC input channel select (5 = DAC0_OUT) */
#define ADC0_SC1_ADCH_AD5 (5u)
#define ADC0_SC1_SGL_DAC0 (ADC0_SC1_ADCH_AD5)
/*-----------------------------------------------------------*/
/* ADC0_SC2:  ADC0 status and control register 2             */
/*  0-->31-8:(reserved):read-only:0                          */
/*  0-->   7:ADACT=ADC conversion active                     */
/*  0-->   6:ADTRG=ADC conversion trigger select:  software  */
/*  0-->   5:ACFE=ADC compare function enable                */
/*  X-->   4:ACFGT=ADC compare function greater than enable  */
/*  0-->   3:ACREN=ADC compare function range enable         */
/*            0=disabled; only ADC0_CV1 compared             */
/*            1=enabled; both ADC0_CV1 and ADC0_CV2 compared */
/*  0-->   2:DMAEN=DMA enable                                */
/* 01--> 1-0:REFSEL=voltage reference selection:  VDDA       */
#define ADC0_SC2_REFSEL_VDDA (1u)
#define ADC0_SC2_SWTRIG_VDDA (ADC0_SC2_REFSEL_VDDA)
/*-------------------------------------------------------------*/
/* ADC0_SC3:  ADC0 status and control register 3               */
/* 31-8:(reserved):read-only:0                                 */
/*  0-->   7:CAL=calibration                                   */
/*          write:0=(no effect)                                */
/*                1=start calibration sequence                 */
/*          read:0=calibration sequence complete               */
/*               1=calibration sequence in progress            */
/*  0-->   6:CALF=calibration failed flag                      */
/* 00--> 5-4:(reserved):read-only:0                            */
/*  0-->   3:ADCO=ADC continuous conversion enable             */
/*           (if ADC0_SC3.AVGE = 1)                            */
/*  0-->   2:AVGE=hardware average enable                      */
/* XX--> 1-0:AVGS=hardware average select:  2^(2+AVGS) samples */
#define ADC0_SC3_SINGLE (0u)
#define ADC0_SC3_CAL (ADC_SC3_CAL_MASK | ADC_SC3_AVGE_MASK | \
                                           ADC_SC3_AVGS_MASK)
/*-------------------------------------------------------------*/
/* DAC */
#define DAC_DATH_MIN   (0x00u)
#define DAC_DATL_MIN   (0x00u)
/*---------------------------------------------------------------------*/
/* DAC_C0:  DAC control register 0                                     */
/* 1-->7:DACEN=DAC enabled                                             */
/* 1-->6:DACRFS=DAC reference select VDDA                              */
/* 0-->5:DACTRGSEL=DAC trigger select (X)                              */
/* 0-->4:DACSWTRG=DAC software trigger (X)                             */
/* 0-->3:LPEN=DAC low power control:high power                         */
/* 0-->2:(reserved):read-only:0                                        */
/* 0-->1:DACBTIEN=DAC buffer read pointer top flag interrupt enable    */
/* 0-->0:DACBBIEN=DAC buffer read pointer bottom flag interrupt enable */
#define DAC_C0_ENABLE  (DAC_C0_DACEN_MASK | DAC_C0_DACRFS_MASK)
/*----------------------------------------*/
/* DAC_C1:  DAC control register 1        */
/* 0-->  7:DMAEN=DMA disabled             */
/* 0-->6-3:(reserved)                     */
/* 0-->  2:DACBFMD=DAC buffer mode normal */
/* 0-->  1:(reserved)                     */
/* 0-->  0:DACBFEN=DAC buffer disabled    */
#define DAC_C1_BUFFER_DISABLED  (0x00u)
/*-------------------------------------------------------------*/
/* PORTx_PCRn                                                  */
/*     -->31-25:(reserved):read-only:0                         */
/*    1-->   24:ISF=interrupt status flag (write 1 to clear)   */
/*     -->23-20:(reserved):read-only:0                         */
/* 0000-->19-16:IRQC=interrupt configuration (IRQ/DMA diabled) */
/*     -->15-11:(reserved):read-only:0                         */
/*  ???-->10- 8:MUX=pin mux control                            */
/*     -->    7:(reserved):read-only:0                         */
/*    ?-->    6:DSE=drive strengh enable                       */
/*     -->    5:(reserved):read-only:0                         */
/*    0-->    4:PFE=passive filter enable                      */
/*     -->    3:(reserved):read-only:0                         */
/*    0-->    2:SRE=slew rate enable                           */
/*    0-->    1:PE=pull enable                                 */
/*    x-->    0:PS=pull select                                 */
/* Port B */
/*   DAC0_OUT connects through PTB1 to FRDM-KL05Z J8 pin 2 (D1)*/
/*   This connection is not compatible with UART0 USB COM port */
#define PTB1_MUX_DAC0_OUT (0u << PORT_PCR_MUX_SHIFT)
#define SET_PTB1_DAC0_OUT (PORT_PCR_ISF_MASK | PTB1_MUX_DAC0_OUT)
/*   TPM0_CH3_OUT connects through PTB8                        */
/*     to FRDM-KL05Z red LED connects to PTB8                  */
#define PTB8_MUX_TPM0_CH3_OUT (2u << PORT_PCR_MUX_SHIFT)
#define SET_PTB8_TPM0_CH3_OUT (PORT_PCR_ISF_MASK | \
                               PTB8_MUX_TPM0_CH3_OUT)
/*-------------------------------------------------------*/
/* SIM_SOPT2                                             */
/*   -->31-28:(reserved):read-only:0                     */
/*   -->27-26:UART0SRC=UART0 clock source select         */
/* 01-->25-24:TPMSRC=TPM clock source select (MCGFLLCLK) */
/*   -->23-19:(reserved):read-only:0                     */
/*   -->   18:USBSRC=USB clock source select             */
/*   -->17-16:(reserved):read-only:00                    */
/*   -->15- 8:(reserved):read-only:0                     */
/*   --> 7- 5:CLKOUTSEL=CLKOUT select                    */
/*   -->    4:RTCCLKOUTSEL=RTC clock out select          */
/*   --> 3- 0:(reserved):read-only:0                     */
#define SIM_SOPT2_TPMSRC_MCGFLLCLK (1u << SIM_SOPT2_TPMSRC_SHIFT)
/*------------------------------------------------------------------*/
/* TPMx_CONF:  Configuration (recommended to use default values     */
/*     -->31-28:(reserved):read-only:0                              */
/* 0000-->27-24:TRGSEL=trigger select (external pin EXTRG_IN)       */
/*     -->23-19:(reserved):read-only:0                              */
/*    0-->   18:CROT=counter reload on trigger                      */
/*    0-->   17:CSOO=counter stop on overflow                       */
/*    0-->   16:CSOT=counter stop on trigger                        */
/*     -->15-10:(reserved):read-only:0                              */
/*    0-->    9:GTBEEN=global time base enable                      */
/*     -->    8:(reserved):read-only:0                              */
/*   00-->  7-6:DBGMODE=debug mode (paused in debug)                */
/*    0-->    5:DOZEEN=doze enable                                  */
/*     -->  4-0:(reserved):read-only:0                              */
/* 15- 0:COUNT=counter value (writing any value will clear counter) */
#define TPM_CONF_DEFAULT (0u)
/*------------------------------------------------------------------*/
/* TPMx_CNT:  Counter                                               */
/* 31-16:(reserved):read-only:0                                     */
/* 15- 0:COUNT=counter value (writing any value will clear counter) */
#define TPM_CNT_INIT (0u)
/*------------------------------------------------------------------------*/
/* TPMx_MOD:  Modulo                                                      */
/* 31-16:(reserved):read-only:0                                           */
/* 15- 0:MOD=modulo value (recommended to clear TPMx_CNT before changing) */
/* Period = TPM_SOURCE_FREQ / (2 << TPM_SC_PS_DIV16) / PWM_FREQ           */
#define TPM_PWM_PERIOD ((TPM_SOURCE_FREQ / (1 << TPM_SC_PS_VAL)) / \
                            PWM_FREQ)
#define TPM_MOD_PWM_PERIOD (TPM_PWM_PERIOD - 1)
/*------------------------------------------------------------------*/
/* TPMx_CnSC:  Channel n Status and Control                         */
/* 0-->31-8:(reserved):read-only:0                                  */
/* 0-->   7:CHF=channel flag                                        */
/*              set on channel event                                */
/*              write 1 to clear                                    */
/* 0-->   6:CHIE=channel interrupt enable                           */
/* 1-->   5:MSB=channel mode select B (see selection table below)   */
/* 0-->   4:MSA=channel mode select A (see selection table below)   */
/* 1-->   3:ELSB=edge or level select B (see selection table below) */
/* 0-->   2:ELSA=edge or level select A (see selection table below) */
/* 0-->   1:(reserved):read-only:0                                  */
/* 0-->   0:DMA=DMA enable                                          */
#define TPM_CnSC_PWMH (TPM_CnSC_MSB_MASK | TPM_CnSC_ELSB_MASK)
/*--------------------------------------------------------*/
/* TPMx_CnV:  Channel n Value                             */
/* 31-16:(reserved):read-only:0                           */
/* 15- 0:MOD (all bytes must be written at the same time) */
#define TPM_CnV_PWM_DUTY_LED_OFF (TPM_MOD_PWM_PERIOD)
#define TPM_CnV_PWM_DUTY_LED_ON  (0)
/*--------------------------------------------------------------*/
/* TPMx_SC:  Status and Control                                 */
/*    -->31-9:(reserved):read-only:0                            */
/*   0-->   8:DMA=DMA enable                                    */
/*    -->   7:TOF=timer overflow flag                           */
/*   0-->   6:TOIE=timer overflow interrupt enable              */
/*   0-->   5:CPWMS=center-aligned PWM select (edge align)      */
/*  01--> 4-3:CMOD=clock mode selection (count each TPMx clock) */
/* 100--> 2-0:PS=prescale factor selection                      */
/*    -->        can be written only when counter is disabled   */
#define TPM_SC_CMOD_CLK (1u)
#define TPM_SC_PS_VAL  (0x4u)
#define TPM_SC_CLK_DIV ((TPM_SC_CMOD_CLK << TPM_SC_CMOD_SHIFT) | \
                        TPM_SC_PS_VAL)

//const UInt16 *DAC0_table = &DAC0_table_0;
const UInt16 *PWM_duty_table = &PWM_duty_table_0;

void Init_TPM0 (void) {
/*********************************************************************/
/* Initialize TPM0 channel 3 for edge-aligned PWM at 60 Hz           */
/* (8.3333 ms) on Port B Pin 8 (red LED)                             */
/*********************************************************************/
	/* Enable TPM0 module clock */ 
	SIM->SCGC6 |= SIM_SCGC6_TPM0_MASK; 
	/* Enable port B module clock */ 
	SIM->SCGC5 |= SIM_SCGC5_PORTB_MASK; 
	/* Connect TPM0 channel 3 to port B pin 8 */ 
	PORTB->PCR[8] = SET_PTB8_TPM0_CH3_OUT; 
	/* Set TPM clock source */ 
	SIM->SOPT2 &= ~SIM_SOPT2_TPMSRC_MASK; 
	SIM->SOPT2 |= SIM_SOPT2_TPMSRC_MCGFLLCLK; 
	/* Set TPM0 configuration register to default values */ 
	TPM0->CONF = TPM_CONF_DEFAULT; 
	/* Set TPM0 counter modulo value */ 
	TPM0->CNT = TPM_CNT_INIT; 
	TPM0->MOD = TPM_MOD_PWM_PERIOD - 1; 
	/* Set TPM0 counter clock configuration */ 
	TPM0->SC = TPM_SC_CLK_DIV; 
	/* Set TPM0 channel 3 edge-aligned PWM */ 
	TPM0->CONTROLS[3].CnSC = TPM_CnSC_PWMH; 
	/* Set TPM0 channel 3 value */ 
	TPM0->CONTROLS[3].CnV = TPM_CnV_PWM_DUTY_LED_ON;
	
} /* Init_TPM0 */  

int getValue(int input){
	int TableIndex;
	TableIndex = input - 48 - 1;  //convert user input to number and set the right index
	return TableIndex;
}
	

int main (void) {
	
	char input;
	int index;
	
  __asm("CPSID   I");  /* mask interrupts */
  /* Perfrom all device initialization here */
  /* before unmasking interrupts            */
  Init_TPM0 ();
  Init_UART0_IRQ ();
  __asm("CPSIE   I");  /* unmask interrupts */
	

  for (;;) { /* do forever */
		
		/*print prompt*/
    PutStringSB("Type a number from 1 to 5: ", MAX_STRING);
		
		/*take user input*/
		do {
		input = GetChar();
		} while (input < '1' || input > '5');
		
		/*echo output*/
		PutChar(input);
		
		/* Print newline to the screen */
		PutStringSB("\r\n", 3);
		/*echo output brightness*/
		PutStringSB("           LED brightness: ", MAX_STRING);
		PutChar(input);
		PutStringSB("\r\n", 3);
		
		/*obtain index for table*/
		index = getValue(input);	
		
		/*change value of the PWM duty cycle as per user input*/
		TPM0->CONTROLS[3].CnV = PWM_duty_table[index];
		
		PutStringSB("\r\n", 3);				
  } /* do forever */

  return (0);
} /* main */
