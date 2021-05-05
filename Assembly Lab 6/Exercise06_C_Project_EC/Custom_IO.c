/***************************************************************/
/* Definitions for module to support I/O based on UART         */
/* character I/O.                                              */
/* R. W. Melton                                                */
/* 3/1/2021                                                    */
/***************************************************************/

#include "MKL05Z4.h"
#include "Custom_IO.h"

/* Boolean values */
#define FALSE (0)
#define TRUE (1)

/* Output characteristics */
#define MAX_WORD_DECIMAL_DIGITS (10)

/* Convert binary value of nibble to ASCII character */
#define HEXN2ASCII(NIBBLE) ((NIBBLE) < 10 ? ((NIBBLE) + '0') : \
                                            ((NIBBLE) - 10 + 'A'))

/* Provided by this module */
uint32_t GetStringSB (char *String, uint32_t Capacity) {
/***************************************************************/
/* Fills String with input from UART until carriage return     */
/* encountered, (which is not stored in String), and then adds */
/* null termination.  Any characters after the first           */
/* Capacity - 1 are accepted but not stored.  All stored       */
/* characters are also output to UART.                         */
/* Returns the number of characters stored in the string,      */
/* not including the NULL character.                           */
/* Uses:  GetChar (from a separate UART module)                */
/*        PutChar (from a separate UART module)                */
/*        PutStringSB                                          */
/***************************************************************/
  char Character;
  int  CharacterCount = 0,
       NotFinished = TRUE;
  
  if (Capacity) {
    /* Room in string */
    while (NotFinished) {
      Character = GetChar ();
      if ((Character >= ' ') && (Character < 0x7F)) {
        /* Standard ASCII character code */
        if (CharacterCount < (Capacity - 1)) {
          /* Room in string for character */
          PutChar (Character);
          *(String++) = Character;
          CharacterCount++;
        } /* if (CharacterCount < (Capacity - 1)) */
        /* else ignore character */
      } /* if (Standard ASCII character code) */
      else if (Character == '\r') {
        NotFinished = FALSE;
      } /* else if ('\r') */
      else if (Character == '\b') {
        if (CharacterCount) {
          /* String has a previous character to remove */
          PutStringSB ("\b \b", 4); /* blank on terminal */
          String--;
          CharacterCount--;
        }
        /* else ignore backspace since no previous character */
      } /* else if ('\b') */
      else if (Character == '\x1B') {
        /* Escape character may start escape sequence */
        if (GetChar () == '[') {
          /* Escape sequence has begun */
          /* Consume characters until tilde (end of escape sequence) */
          while (GetChar () != '~');
        } /* if ('[') */
      } /* else if ('\x1B') */
      /* else ignore ASCII control code */
    } /* while (NotFinished) */
    *String = '\0';
  } /* if (Capacity) */
  else { /* no bytes allocated for string */
    /* Consume characters until carriage return */
    while (GetChar () != '\r');
  } /* else */
  PutStringSB ("\r\n", 3);
  return (CharacterCount);
}

void PutNumU (uint32_t Number) {
/***************************************************************/
/* Prints text representation of unsigned word (32-bit) in a   */
/* minimum number of characters.                               */
/* number.                                                     */
/* Uses:  PutString                                            */
/***************************************************************/
  /* String for number digits up to 4 billion */
  char String[MAX_WORD_DECIMAL_DIGITS + 1];
  char *StringPtr;

  StringPtr = &(String[MAX_WORD_DECIMAL_DIGITS]);
  *StringPtr = 0;
  
  do {
    /* next least significant digit is remainder of division by 10 */
    *(--StringPtr) = ((char) (Number % 10u)) + '0';
    /* rest of number to print */
    Number /= 10u; 
  } while (Number > 0);
  /* print text digits of number */
  PutStringSB (StringPtr, (MAX_WORD_DECIMAL_DIGITS + 1));
} /* PutNumU */

void PutStringSB (char *String, uint32_t Capacity) {
/***************************************************************/
/* Puts null-terminated String to screen.                      */
/***************************************************************/
  char Character = TRUE;  /* Nonzero value to enter while loop */
  char *StringPast;
  
  StringPast = String + Capacity;
  while ((String < StringPast) && Character) {
    if (Character = *(String++)) {
      /* Character is not NULL */
      PutChar (Character);
    } /* if */
  } /* while */
} /* PutStringSB */
