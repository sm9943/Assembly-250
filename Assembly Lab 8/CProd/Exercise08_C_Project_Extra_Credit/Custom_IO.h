/***************************************************************/
/* Definitions for module to support I/O based on UART         */
/* character I/O.                                              */
/* R. W. Melton                                                */
/* 3/8/2021                                                    */
/***************************************************************/

/* Provided by UART character I/O module */
char GetChar (void);
void PutChar (char Character);

/* Provided by this module */
uint32_t GetStringSB (char *String, uint32_t Capacity);
uint32_t LengthStringSB (char *String, uint32_t Capacity);
void PutNumHex (uint32_t Number);
void PutNumHexB (uint8_t NumberB);
void PutNumU (uint32_t Number);
void PutNumUB (uint8_t NumberB);
void PutStringSB (char *String, uint32_t Capacity);
