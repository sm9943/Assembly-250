/*********************************************************************/
/* Lab Exercise Eight Extra Credit                                   */
/* Tests input, addition, and output of 96-bit unsigned numbers.     */
/* Prompts user to enter two numbers in hex format to add,           */
/* computes the result, and prints it.                               */
/* Name:  R. W. Melton                                               */
/* Date:  March 15, 2021                                             */
/* Class:  CMPE 250                                                  */
/* Section:  All sections                                            */
/*********************************************************************/
#include <MKL05Z4.h>
#include "UART0_Polling.h"
#include "Custom_IO.h"

#define FALSE       (0)
#define TRUE        (1)
#define NULL        (0)
#define NUMBER_BITS (96)
/* Bytes:  BITS * (1 BYTE / 8 BITS) */
#define NUMBER_BYTES (NUMBER_BITS >> 3)
/* Words:  BITS * (1 WORD / 32 BITS) */
#define NUMBER_WORDS  (NUMBER_BITS >> 5)
/* Max hex string:  BITS * (1 Hex Digit / 4 BITS) + 1 */
#define MAX_HEX_STRING ((NUMBER_BITS >> 2) + 1)

typedef char Int8;
typedef unsigned char UInt8;
typedef int Int32;
typedef unsigned int UInt32;
typedef union {
  UInt32 Word[NUMBER_WORDS];
  UInt8  Byte[NUMBER_BYTES];
} UInt96;

/* Access to APSR provided as defined in core_cm0plus.h */
register APSR_Type APSR __asm("apsr");
register unsigned int R6 __asm("r6");
register unsigned int R7 __asm("r7");

int AddIntMultiU (UInt32 *Sum, UInt32 *Augend, UInt32 *Addend, 
                  int NumWords) {
/*********************************************************************/
/* Adds two multiword unsigned numbers:  Sum = Augend + Addend       */
/* If result overflows, returns 1; otherwise returns 0.              */
/*********************************************************************/
  unsigned int SavedC = 0,
               SavedR6,
               SavedR7;
  int Index;

  /*Preserve R6 and R7 for APCS compliance */
  SavedR6 = R6;
  SavedR7 = R7;

  for (Index = 0; Index < NumWords; Index++) {
    R6 = Augend[Index];
    R7 = Addend[Index];
    APSR.b.C = SavedC;
    __asm("ADCS R6,R6,R7");
    SavedC = APSR.b.C;
    Sum[Index] = R6;
  }

  /* Restore original R6 and R7 for APCS compliance */
  R6 = SavedR6;
  R7 = SavedR7;
  return (SavedC);
}

int GetHexIntMulti (UInt32 *Number, int NumWords) {
/*********************************************************************/
/* Gets user string input of hex representation of an multiword      */
/* unsigned number of NumWords words, and converts it to a binary    */
/* unsigned NumWords-word number.                                    */
/* If user input is invalid, returns 1; otherwise returns 0.         */  
/* Calls:  GetString                                                 */
/*********************************************************************/
  UInt8  *StringPtr;
  UInt8  Digit;
  UInt8  String[MAX_HEX_STRING];
  UInt8 *BytePtr;
  UInt8 ByteValue;
  int   NoError;  /* Used for index and error condition */

  /* Initialize *Number to 0 */
  for (NoError = 0; NoError < NumWords; NoError++) {
    Number [NoError] = (UInt32) 0;
  }

  if (NoError = GetStringSB ((char *) String, MAX_HEX_STRING)) {
    /* String is not empty */
    StringPtr = &(String[NoError]);
    NoError = TRUE;

    /* Convert each hex digit to binary */
    BytePtr = (UInt8 *) Number;
    ByteValue = (UInt8) 0;
    while (NoError && (StringPtr > String)) {
      /* Convert least significant digit of byte*/
      Digit = *(--StringPtr);
      /* Convert ASCII value to binary  value */
      if ((Digit >= '0') && (Digit <= '9')) {
        ByteValue =  (UInt8) (Digit - '0');
      }
      else if ((Digit >= 'A') && (Digit <= 'F')) {
        ByteValue =  (UInt8) (Digit - 'A' + (char) 10);
      }
      else if ((Digit >= 'a') && (Digit <= 'f')) {
        ByteValue =  (UInt8) (Digit - 'a' + (char) 10);
      }
      else {
        NoError = FALSE;
        ByteValue = (UInt8) 0;
      }

      /* Convert most significant digit of byte */
      if (NoError && (StringPtr > String)) {
        Digit = *(--StringPtr);
        /* Convert ASCII value to binary  value */
        if ((Digit >= '0') && (Digit <= '9')) {
          Digit -= '0';
        }
        else if ((Digit >= 'A') && (Digit <= 'F')) {
          Digit = Digit - 'A' + (char) 10;
        }
        else if ((Digit >= 'a') && (Digit <= 'f')) {
          Digit = Digit - 'a' + (char) 10;
        }
        else {
          Digit = (char) 0;
          NoError = FALSE;
        }
      }
      else { /*no more digits typed */
        Digit = (char) 0;
      }
      /* Pack nibbles values into byte */
      *(BytePtr++) = ByteValue | (UInt8) (Digit << 4);
    } /* while */
  } /* if */
  else {
    /* String empty */
    NoError = FALSE;
  }
  
  /* complement of NoError is return result */
  return (NoError ^ 1);  
} /* GetHexIntMulti */

void PutHexIntMulti (UInt32 *Number, int NumWords) {
/*********************************************************************/
/* Prints hex representation of an unsigned multi-word number of     */
/* NumWords words.                                                   */
/* Calls:  PutNumHex                                                 */
/*********************************************************************/
  int Index;

  for (Index = NumWords - 1; Index >= 0; Index--) {
    PutNumHex (Number [Index]);
  }
} /* PutHexIntMulti */
  
int main (void) {
  static const char outputOverflow[] = "OVERFLOW\r\n";
  static const char outputSum[] =      "                           Sum:  0x";
  static const char promptAddend[] =   "Enter 96-bit hex number to add:  0x";
  static const char promptAugend[] =   " Enter first 96-bit hex number:  0x";
  static const char promptInvalid[] =  "     Invalid number--try again:  0x";
  static const char stringCRLF[] = "\r\n";
  int NotFinished = TRUE;
  UInt96 Addend,
         Augend,
         Sum;

  Init_UART0_Polling ();

  while (NotFinished) {
    /* Get first number */
    PutStringSB ((char *) promptAugend, sizeof (promptAugend));
    while (GetHexIntMulti (Augend.Word, NUMBER_WORDS)) {
      PutStringSB ((char *) promptInvalid, sizeof (promptInvalid));
    } /* while GetHexIntMulti */
    
    /* Get second number */
    PutStringSB ((char *) promptAddend, sizeof (promptAddend));
    while (GetHexIntMulti (Addend.Word, NUMBER_WORDS)) {
      PutStringSB ((char *) promptInvalid, sizeof (promptInvalid));
    } /* while GetHexIntMulti */

    /* Output sum */
    PutStringSB ((char *) outputSum, sizeof (outputSum));
    if (AddIntMultiU (Sum.Word, Augend.Word, Addend.Word, NUMBER_WORDS)) {
      PutStringSB ((char *) outputOverflow, sizeof (outputOverflow));
    }
    else { /* result was valid */
      PutHexIntMulti (Sum.Word, NUMBER_WORDS);
      PutStringSB ((char *) stringCRLF, sizeof (stringCRLF));
    }
  } /* while (NotFinished) */
  return (0);
} /* main */
