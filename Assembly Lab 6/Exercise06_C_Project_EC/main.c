/* Program prompts to enter a command character, and gets a    */
/* character typed on the terminal keyboard.  If the character */
/* is not a command character, (i.e., "G," "I," "L," or "P,"   */
/* regardless of case), the program repeatedly gets characters */
/* typed until the character is a command character.  After a  */
/* valid command character is received, the program prints the */
/* character received, advances to the beginning of the next   */
/* line of the terminal screen, and then does the action(s)    */
/* listed below based on the command.  After the command, the  */
/* program repeats, starting with the program prompt at the    */
/* beginning of a new line on the terminal screen.             */
/*     G or g:  Gets a string from the user for the            */
/*              operational string contents                    */
/*     I or i:  Sets the operational string to the empty       */
/*              string                                         */
/*     L or l:  Prints the length of the operational string    */
/*     P or p:  Prints the operational string                  */
/*                                                             */
/* Name:  R. W. Melton                                         */
/* Date:  March 1, 2021                                        */
/* Class:  CMPE-250                                            */
/* Section:  All sections                                      */
/***************************************************************/
#include <MKL05Z4.h>
#include "UART0_Polling.h"
#include "Custom_IO.h"
#include "Exercise06_Lib.h"

/* Boolean values */
#define FALSE (0)
#define TRUE (1)

/* Buffer size for operational string */
#define MAX_STRING (79)

/* Convert upper-case character to lower-case character */
#define LOWER2UPPER(CHARACTER) \
  (((CHARACTER >= 'a') && (CHARACTER <= 'z')) ? \
    (CHARACTER - ('a' - 'A')) : CHARACTER)

/* global constants */
const static char PromptString[] = "Type a string command (G,I,L,P):";
const static char NewLineString[] = "\r\n";
const static char LengthCmdString[] = "Length:";

/* global variables */
char String[MAX_STRING];

int main (void) {
  char Command;
  char WaitForValidCommand;

  Init_UART0_Polling ();
  do {
    /* Get character command */
    PutStringSB ((char *)PromptString, sizeof (PromptString));
    WaitForValidCommand = TRUE;
    do {
      Command = GetChar ();
      switch (LOWER2UPPER(Command)) {
        case 'G' : {
          WaitForValidCommand = FALSE;
          PutChar (Command);
          PutStringSB ((char *) NewLineString, sizeof (NewLineString));
          PutChar ('<');
          GetStringSB (String, MAX_STRING);
          break;
        } /* case 'G' */
        case 'I' : {
          WaitForValidCommand = FALSE;
          PutChar (Command);
          PutStringSB ((char *) NewLineString, sizeof (NewLineString));
          *String = '\0';
          break;
        } /* case 'I' */
        case 'L' : {
          WaitForValidCommand = FALSE;
          PutChar (Command);
          PutStringSB ((char *) NewLineString, sizeof (NewLineString));
          PutStringSB ((char *) LengthCmdString, sizeof (LengthCmdString));
          PutNumU (LengthStringSB (String, MAX_STRING));
          PutStringSB ((char *) NewLineString, sizeof (NewLineString));
          break;
        } /* case 'L' */
        case 'P' : {
          WaitForValidCommand = FALSE;
          PutChar (Command);
          PutStringSB ((char *) NewLineString, sizeof (NewLineString));
          PutChar ('>');
          PutStringSB (String, MAX_STRING);
          PutChar ('>');
          PutStringSB ((char *) NewLineString, sizeof (NewLineString));
          break;
        } /* case 'P' */
      } /* switch (UPPER2LOWER(Command)) */
    } while (WaitForValidCommand);
  } while (TRUE);
} /* main */
