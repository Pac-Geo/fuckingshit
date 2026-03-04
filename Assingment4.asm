; FileName: TempController
; Author: Geovani Palomec
; Date: 3/7/26
; MPLAB Version: v6.30
;------------------------------------------------------------------------------
; Program Vervsion: V2
; Patch notes of V; Updated code and implemented comments & Hex-Dec conversion
; Purpose: Measure, Set and adjust temp accordingly.
; Inputs: Temperature readings
; Outputs: PortD
; Instructions:	DO NOT TOUCH
; Dependencies:	<xc.inc>
    
processor 18F47K42
#include <xc.inc>

;----------------
; PROGRAM INPUTS
;----------------
;The DEFINE directive is used to create macros or symbolic names for values.
;It is more flexible and can be used to define complex expressions or sequences 
;of instructions. It is processed by the preprocessor before assembly begins.

#define  measuredTempInput  45	; this is the input value
#define  refTempInput       25	; this is the input value

;---------------------
; Definitions
;---------------------
#define SWITCH    LATD,2  
#define LED0      PORTD,0
#define LED1      PORTD,1
    
;---------------------
; Program Constants 
;---------------------
; The EQU (Equals) directive is used to assign a constant value to a symbolic 
;name or label. It is simpler and is typically used for straightforward 
; assignments. It directly substitutes the defined value into the code 
;during the assembly process.
    REG10   equ     10h // in Hex
    REG11   equ     11h
    REG01   equ     1h

;----------------------------
; Constants defined with proper register numbers (R8)
;----------------------------
   
    refTempReg   equ 20h   ; refTemp -> REG 0x20
    measTempReg  equ 21h   ; measuredTemp -> REG 0x21
    contReg      equ 22h   ; contReg -> REG 0x22

;constants used for conversion
    count        equ 30h
    number       equ 31h
    tmp          equ 32h

; BCD output constants
; REF digits:
    REF_ONES     equ 60h   ; ones digit of ref temp (ex: 44 -> 4)
    REF_TENS     equ 61h   ; tens digit of ref temp (ex: 44 -> 4)
    REF_HUND     equ 62h   ; hundreds digit (almost always 0 here)

; MEASURED digits:
    MEA_ONES     equ 70h
    MEA_TENS     equ 71h
    MEA_HUND     equ 72h

;----------------------------
; Jump to main when the PIC powers on, it begins at address 0x000
;----------------------------
    org 0x000
    goto main
    
;----------------------------
; Main program starts at 0x20 
;----------------------------
    org 0x020	;R7 start from register 0x20 in the program memory.
    
main:
; R6 Initialize PORTD ONLY as outputs and clear 
    banksel TRISD
    clrf    TRISD	; make PORTD pins outputs
    banksel PORTD
    clrf    PORTD	; start with PORTD all OFF
    banksel LATD
    clrf    LATD	;clear latch
    
; Put the ARBITRARY TEST values 
    movlw   0x05	    ; refTemp  
    banksel refTempReg
    movwf   refTempReg
    
    movlw   0x06	    ; measuredTemp 
    banksel measTempReg
    movwf   measTempReg

; ----------------------------
; Perform comparison
; ----------------------------
    banksel measTempReg
    btfsc   measTempReg, 7    ; if measured negative -> treat as HEAT
    goto    SET_HEAT
    
    banksel refTempReg
    movf    refTempReg, W
    subwf   measTempReg, W  ; W = measured - ref  (status bits set)

;If measuredTemp = refTemp, Z=1, then set contReg=0 goto ledoff
    btfsc   STATUS, 2	   
    goto    SET_EQUAL	    ;LED OFF 

;If measuredTemp > refTemp then set contReg=2 
;C=1 (no borrow) indicates measured > ref
    btfsc   STATUS, 0      
    goto    SET_COOL	    ;LED is HOT

; Else measured < ref set contReg=1 
    goto    SET_HEAT	    ;LED is COOL
    
; ----------------------------
; Branch targets implementing actions R1-R3
; ----------------------------
SET_EQUAL:
    ;set contReg=0
    movlw   0x00
    banksel contReg
    clrf    contReg
    goto    LED_OFF

SET_COOL:
    ;set contReg=2
    movlw   0x02
    banksel contReg
    movwf   contReg
    goto    LED_COOL

SET_HEAT:
    ;set contReg=1
    movlw   0x01
    banksel contReg
    movwf   contReg
    goto    LED_HOT
    
; ----------------------------
; LED labels
; ----------------------------
LED_COOL:
    ;turn on PORTD2, turn off PORTD1
    ; TURN OFF hotAir
    ; TURN OFF coolAir
    banksel LATD
    bsf     SWITCH         ; set LATD,2 -> turns PORTD.2 output high
    banksel PORTD
    bcf     LED1           ; ensure HEAT (PORTD.1) is OFF
    goto    HEX_TO_DEC

LED_HOT:
    ;turn on PORTD1, turn off PORTD2
    ; Display H, ?display? = set outputs
    ; TURN ON hotAir
    ; TURN OFF coolAir
    banksel PORTD
    bsf     LED1           ; set PORTD.1 -> HEAT ON
    banksel LATD
    bcf     SWITCH         ; clear LATD,2 -> COOL OFF
    goto    HEX_TO_DEC

LED_OFF:
    ; Display nothing & TURN OFF all
    ;turn off both PORTDs
    banksel PORTD
    bcf     LED1           ; HEAT OFF
    banksel LATD
    bcf     SWITCH         ; COOL OFF
    goto    HEX_TO_DEC
    
;==========================================================
;   refTempReg  -> 0x62(100s), 0x61(10s), 0x60(1s)
;   measTempReg -> 0x72(100s), 0x71(10s), 0x70(1s)
;==========================================================

HEX_TO_DEC:
;-----------------------------
; Convert refTempReg -> REF_HUND/REF_TENS/REF_ONES
;-----------------------------
    clrf    count
    movf    refTempReg, W
    movwf   number
    movlw   100

Loop100sRef:
    incf    count, F
    subwf   number, F	    ;F=F-W 
    bc      Loop100sRef	    ; keep subtracting while Carry=1 (no borrow)
    decf    count, F
    addwf   number, F	    ; add 100 back once
    movff   count, REF_HUND ; 0x62

    clrf    count
    movlw   10		    ;Set up for tens place

Loop10sRef:
    incf    count, F
    subwf   number, F
    bc      Loop10sRef
    decf    count, F
    addwf   number, F         ; add 10 back once
    movff   count, REF_TENS   ; 0x61
    movff   number, REF_ONES  ; 0x60
;-----------------------------
; Convert measTempReg -> MEA_HUND/MEA_TENS/MEA_ONES
;-----------------------------
    clrf    count
    movf    measTempReg, W
    movwf   number
; abs(measuredTempReg) fro negative measurement vals
    btfss   number, 7        ; if bit7 = 0, already positive
    goto    MeasPos
    comf    number, F        ; two's complement: invert
    incf    number, F        ; +1
MeasPos:
    movlw   100

Loop100sMeas:
    incf    count, F
    subwf   number, F		;F=F-W
    bc      Loop100sMeas	; keep subtracting until Carry=0 (borrow)
    decf    count, F
    addwf   number, F
    movff   count, MEA_HUND	; 0x72
    clrf    count
    movlw   10			; Set up for tenths place

Loop10sMeas:
    incf    count, F
    subwf   number, F
    bc      Loop10sMeas
    decf    count, F
    addwf   number, F
    movff   count, MEA_TENS	; 0x71
    movff   number, MEA_ONES	; 0x70

    goto    ENDPROG           ; go back to your end/idle loop
   
ENDPROG:
    end 