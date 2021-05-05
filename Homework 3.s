TTL   Homework Assignment 3
;****************************************************************
; Author: Shubhang Mehrotra
; Date: 03/05
;****************************************************************

;*********************Problem 1**********************
; psuedocode:
;
;   for (R0 = 0; R0 < 80; R0++)
;         String[R0] = String[R0] XOR 0x5A
;
;********part a**********
; Conditional Loop Control
; Indexed Mode Addressing: [RBase, RIndex]

			;R0 = 0
			MOVS   R0,#0                    ;Initialize R0
            
            ;R1 = 80
			MOVS   R1,#0x50                 ;Loading compare value to register

			;R2 = 0x5A
            MOVS   R2,#0x5A					;Store 0x5A for XOR

            LDR    R3,=String               ;Load string Pointer 
            LDRB   R4,[R3,R0]               ;Load Character offset	

loop_a      CMP    R0,R1                    ;Check for R0<80
            BGE    end_a                    ;stop loop if not
 
            ;String[R0] XOR 0x5A
            EORS   R4, R4, R2
            STRB   R4,[R3,R0]               ;Store string back

            ;R0++
            ADDS   R0, R0, #1               ;Increment Index    

            B      loop_a                   ;loop back 

end_a       B      .                        ;stop program                      

;********part b**********
; Conditional Loop Control
; Displacement Mode Addressing: [RIndirect, #0]

			;R0 = 0
			MOVS   R0,#0                    ;Initialize R0
            
            ;R1 = 80
			MOVS   R1,#0x50                 ;Loading compare value to register

			;R2 = 0x5A
            MOVS   R2,#0x5A					;Store 0x5A for XOR

            LDR    R3,=String               ;Load string Pointer 
            LDRB   R4,[R3,R0]               ;Load Character offset	


loop_b      CMP    R0,R1                    ;Check for R0<80
            BGE    end_b                    ;stop loop if not

            ;String[R0] XOR 0x5A
            EORS   R4, R4, R2
            STRB   R4,[R3,#0]               ;Store string back

            ;R0++
            ADDS   R0, R0, #1               ;Increment Index    
            
            ;R3++
            ADDS   R3, R3, #1               ;Increment Pointer   

            B      loop_b                   ;loop back

end_b       B      .                        ;stop program


;*********************Problem 2**********************
; Min Subroutine
; Inputs: 
;   R1: Pointer to an array of signed words
;   R2: Number of array elements, word value
; Outputs:
;   R0: Minimum of Array elements
; Modify:
;   Only modify R0 and PSR, 
;   all other registers stay unchanged

; psuedocode:
;
;           min = firstIndexValue
;  do{
;      if(min > currentIndex.Value){
;	       min = currentIndex.Value;
;         } 
;      else{  
;		min = min
;		}
;     }while{arrayHasElementsToCompare}	
;

;******part a****************************************
; Displacement mode Addressing: [R1, #0]
; Manually update array pointer to access each element: ADDS R1...
; Down Counter iteration: (R2 down to 0)

Min 		PROC   {R1-R14}

			PUSH   {R1-R3}				;Register retention
            
            ;min = firstIndexValue
            LDR    R0,[R1,#0] 			;Initialize R0           
            
loop_min_a  CMP    R2, #0               ;check number of array elements 
 			BEQ    end_min              ;if 0, end program

            LDR    R3,[R1,#0]           ;current array element 
			CMP    R0,R3                ;compare min with currentIndex.Value
            BGT    set_min              ;branch if min>currentIndex.Value

            ADDS   R1,R1,#1             ;increment index
            SUBS   R2,R2,#1             ;Decrement number of array elements
            B      loop_min

set_min_a   MOVS   R0,R3                ;min = currentIndex.Value     
            ADDS   R1,R1,#1             ;increment index
            SUBS   R2,R2,#1             ;Decrement number of array elements  
            B      loop_min
end_min_a
			POP    {R1-R3}              ;register retention
			BX     LR                   ;exit subroutine
			ENDP
;******part b****************************************
; Auto-increment using LDM to access each element
; Down Counter iteration: (R2 down to 0) 

Min 		PROC   {R1-R14}

			PUSH   {R1-R3}				;Register retention
            
            ;min = firstIndexValue
            LDR    R0,[R1,#0] 			;Initialize R0           
            
loop_min_b  CMP    R2, #0               ;check number of array elements 
 			BEQ    end_min              ;if 0, end program

            LDM    R1!,R3               ;current array element, with Auto-increment 
			CMP    R0,R3                ;compare min with currentIndex.Value
            BGT    set_min              ;branch if min>currentIndex.Value
            
            SUBS   R2,R2,#1             ;Decrement number of array elements
            B      loop_min

set_min_b   MOVS   R0,R3                ;min = currentIndex.Value 
			SUBS   R2,R2,#1             ;Decrement number of array elements    
            B      loop_min
end_min_b
			POP    {R1-R3}              ;register retention
			BX     LR 					;exit subroutine
			ENDP