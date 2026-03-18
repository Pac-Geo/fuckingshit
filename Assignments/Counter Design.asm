; FileName: Counter Design
; Author: Geovani Palomec
; Course: EE310
; Date: 3/17/26
    
; MPLAB Version: MPLAB X IDE v6.30
; Operating System: Windows 11

; Program Version: V2
; Patch Notes:
;   V2 Implemented set up, and Call functions:
	;CHECK_SWITCH
	;COUNT_UP / DOWN / RESET
	;DELAY
    
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
; DEFENITIONS
;---------------------
; if OPERATION = 1 -> COUNTUP
; if OPERATION = 2 -> COUNTDOWN
; if OPERATION = 3 -> RESET
; else -> NOTHING
    
;------------------------------------------------------------------------------
; VARIABLES
;---------------------
COUNT       equ 0x10
OPERATION   equ 0x11

; Delay registers
REG10       equ 0x12
REG11       equ 0x13
REG12       equ 0x14

Inner_loop  equ 100
Middle_loop equ 50
Outer_loop  equ 50
    
;------------------------------------------------------------------------------   
; PROGRAM ORGINIZATION
;---------------------
PSECT absdata,abs,ovrld        ; Do not change
ORG          0                ;Reset vector
GOTO	     START

ORG          0020H           ; Begin assembly at 0020H
;------------------------------------------------------------------------------
; SET UP & MAIN PROGRAM
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
    BTFSC STATUS, 2
    CALL RESET_COUNT

    MOVF OPERATION, W
    XORLW 0x01
    BTFSC STATUS, 2
    CALL COUNT_UP

    MOVF OPERATION, W
    XORLW 0x02
    BTFSC STATUS, 2
    CALL COUNT_DOWN

    MOVF OPERATION, W
    XORLW 0x00
    BTFSC STATUS, 2
    CALL DO_NOTHING

    GOTO MAIN_LOOP
    
;------------------------------------------------------------------------------
; CALL FUNCTIONS
;-------------------------------------
INITIALIZATION:
    ; Clear PORTD
    BANKSEL PORTD
    CLRF PORTD
    BANKSEL LATD
    CLRF LATD
    BANKSEL ANSELD
    CLRF ANSELD
    BANKSEL TRISD
    CLRF TRISD      ; RD0?RD7 output

    ; Setup PORTB inputs
    BANKSEL PORTB
    CLRF PORTB
    BANKSEL LATB
    CLRF LATB
    BANKSEL ANSELB
    CLRF ANSELB
    BANKSEL TRISB
    MOVLW 0b00000011
    MOVWF TRISB     ; RB0, RB1 input

    ; Initialize count
    CLRF COUNT
    CLRF OPERATION

    RETURN
    
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
    
CHECK_SWITCH:
    CLRF OPERATION

    ; Check BOTH pressed first
    BTFSS PORTB, 0
    GOTO CHECK_A
    BTFSS PORTB, 1
    GOTO CHECK_A

    MOVLW 0x03
    MOVWF OPERATION
    RETURN

CHECK_A:
    BTFSS PORTB, 0
    GOTO CHECK_B

    MOVLW 0x01
    MOVWF OPERATION
    RETURN

CHECK_B:
    BTFSS PORTB, 1
    GOTO NO_PRESS

    MOVLW 0x02
    MOVWF OPERATION
    RETURN

NO_PRESS:
    CLRF OPERATION
    RETURN
    
COUNT_UP:
    INCF COUNT, F

    ; wrap 0?9
    MOVLW 10
    CPFSLT COUNT     ; skip if COUNT < 10
    CLRF COUNT

    CALL DISPLAY_COUNT
    RETURN
    
COUNT_DOWN:
    MOVF COUNT, F
    BTFSC STATUS, 2
    GOTO SET_NINE

    DECF COUNT, F
    CALL DISPLAY_COUNT
    RETURN

SET_NINE:
    MOVLW 9
    MOVWF COUNT
    CALL DISPLAY_COUNT
    RETURN
    
RESET_COUNT:
    CLRF COUNT
    CALL DISPLAY_COUNT
    RETURN

DO_NOTHING:
    CALL DISPLAY_COUNT
    RETURN
    
DELAY:
    MOVLW Inner_loop
    MOVWF REG10
    MOVLW Middle_loop
    MOVWF REG11
    MOVLW Outer_loop
    MOVWF REG12

LOOP1:
    DECF REG10, F
    BNZ LOOP1
    MOVLW Inner_loop
    MOVWF REG10

    DECF REG11, F
    BNZ LOOP1
    MOVLW Middle_loop
    MOVWF REG11

    DECF REG12, F
    BNZ LOOP1
    RETURN
    
END
