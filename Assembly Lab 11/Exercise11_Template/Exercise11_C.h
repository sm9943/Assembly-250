/*********************************************************************/
/* C header file for the PWM-LED program.                            */
/* Name:  Shubhang Mehrotra                                          */
/* Date:  04/26/2021			                                           */
/* Class:  CMPE 250                                                  */
/* Section:  01, Thursday 2 PM                                       */
/*-------------------------------------------------------------------*/
/* Template:  R. W. Melton                                           */
/*            November 3, 2020                                       */
/*********************************************************************/
typedef int Int32;
typedef short int Int16;
typedef char Int8;
typedef unsigned int UInt32;
typedef unsigned short int UInt16;
typedef unsigned char UInt8;

/* assembly language ROM table entries */
//extern const UInt16 DAC0_table_0;
extern const UInt16 PWM_duty_table_0;

/* assembly language subroutines */
char GetChar (void);
void GetStringSB (char String[], int StringBufferCapacity);
void Init_UART0_IRQ (void);
void PutChar (char Character);
void PutNumHex (UInt32);
void PutNumUB (UInt8);
void PutStringSB (char String[], int StringBufferCapacity);
