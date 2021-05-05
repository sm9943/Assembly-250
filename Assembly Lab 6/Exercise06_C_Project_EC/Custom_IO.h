/***************************************************************/
/* Definitions for module to support I/O based on UART         */
/* character I/O.                                              */
/* R. W. Melton                                                */
/* 3/1/2021                                                    */
/***************************************************************/

/* Provided by UART character I/O module */
char GetChar (void);
void PutChar (char Character);

/* Provided by this module */
uint32_t GetStringSB (char *String, uint32_t Capacity);
void PutNumU (uint32_t Number);
void PutStringSB (char *String, uint32_t Capacity);
