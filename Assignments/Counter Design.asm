; FileName: Counter Design
; Author: Geovani Palomec
; Course: EE310
; Date: 3/17/26
    
; MPLAB Version: MPLAB X IDE v6.30
; Operating System: Windows 11

; Program Version: V1
; Patch Notes:
;   V1 - Initial version
    
; Purpose: 
;   Implement a counter system using a 7segment display that increments, 
;   decrements, or resets the count based on user input from push buttons.  
    
; Inputs:
;   RB0 - Increase / Controls Input A
;   RB1 - Decrease / Controls Input B
; Outputs:
;   RD0?RD7 - Output 7segment display 

; Description:
;   The program reads two input switches (RB0 and RB1) to control
;   a counter displayed on a 7-segment display. If RB0 is pressed,
;   the count increments. If RB1 is pressed, the count decrements.
;   If both switches are pressed simultaneously, the count resets
;   to zero. The counter cycles within the range 0?9 and updates
;   the display accordingly.
; Instructions:
;   Press the buttons, DONT TOUCH CODE
	
;------------------------------------------------------------------------------
; INITIALIZATION
;---------------------
processor 18F47K42
#include <xc.inc>
#include "AssemblyConfig.inc"
    
;------------------------------------------------------------------------------   
; PROGRAM ORGINIZATION
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
ORG          0                ;Reset vector
GOTO        _setup

ORG          0020H           ; Begin assembly at 0020H
;------------------------------------------------------------------------------
; Setup & Main Program
;--------------------- 
START:
    CALL INITIALIZATION
    CALL DISPLAY_COUNT

MAIN_LOOP:
    CALL CHECK_SWITCH
    CALL DELAY

    MOVF OPERATION, W

    ; A and B pressed
    XORLW 0x03
    BTFSC STATUS, Z
    CALL RESET_COUNT

    MOVF OPERATION, W
    XORLW 0x01
    BTFSC STATUS, Z
    CALL COUNT_UP

    MOVF OPERATION, W
    XORLW 0x02
    BTFSC STATUS, Z
    CALL COUNT_DOWN

    MOVF OPERATION, W
    XORLW 0x00
    BTFSC STATUS, Z
    CALL DO_NOTHING

    GOTO MAIN_LOOP
    
;------------------------------------------------------------------------------
; Call Functions
;-------------------------------------
DISPLAY_COUNT:
    MOVF COUNT, W
    CALL SEGMENT_TABLE
    MOVWF PORTD
    RETURN

SEGMENT_TABLE:
    ADDWF PCL, F
    RETLW 0b00111111 ; 0
    RETLW 0b00000110 ; 1
    RETLW 0b01011011 ; 2
    RETLW 0b01001111 ; 3
    RETLW 0b01100110 ; 4
    RETLW 0b01101101 ; 5
    RETLW 0b01111101 ; 6
    RETLW 0b00000111 ; 7
    RETLW 0b01111111 ; 8
    RETLW 0b01101111 ; 9
    
END
