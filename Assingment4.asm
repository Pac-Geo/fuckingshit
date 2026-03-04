; FileName: TempController
; Author: Geovani Palomec
; Date: 3/7/26
; MPLAB Version: v6.30
;------------------------------------------------------------------------------
; Program Vervsion: V1
; Patch notes of V; NA
; Purpose: MEasure, Set and adjust temp accordingly.
; Inputs: Temperature readings
; Outputs: PortD
; Instructions:	DO NOT TOUCH
; Dependencies:	<xc.inc>
    
processor 18F47K42
#include <xc.inc>

;----------------
; PROGRAM INPUTS (DO NOT CHANGE)
;----------------
#define  measuredTempInput  45
#define  refTempInput       25

;---------------------
; Definitions (DO NOT CHANGE)
;---------------------
#define SWITCH    LATD,2  
#define LED0      PORTD,0
#define LED1      PORTD,1
    
;---------------------
; Program Constants (DO NOT CHANGE)
;---------------------
REG10   equ     10h
REG11   equ     11h
REG01   equ     1h

;----------------------------
; IMPORTANT RAM LOCATIONS (required by the assignment)
;----------------------------
; These are RAM addresses (like mailboxes).
; We MUST store the temperatures and control value in these exact spots:
refTempReg   equ 20h   ; RAM 0x20 holds the reference temperature (goal temp)
measTempReg  equ 21h   ; RAM 0x21 holds the measured temperature (current temp)
contReg      equ 22h   ; RAM 0x22 holds the decision code (0,1,2)

; extra helper RAM used during math/conversion
count        equ 30h
number       equ 31h
tmp          equ 32h

; Decimal-digit output RAM (required by assignment)
; REF digits:
REF_ONES     equ 60h   ; ones digit of ref temp (ex: 44 -> 4)
REF_TENS     equ 61h   ; tens digit of ref temp (ex: 44 -> 4)
REF_HUND     equ 62h   ; hundreds digit (almost always 0 here)

; MEASURED digits:
MEA_ONES     equ 70h
MEA_TENS     equ 71h
MEA_HUND     equ 72h

;----------------------------
; Reset Vector
;----------------------------
; When the PIC powers on, it begins at address 0x000
org 0x000
    goto main

;----------------------------
; Main program starts at 0x20 (required)
;----------------------------
org 0x020
main:
    ; ==========================================================
    ; STEP A: SETUP OUTPUTS (so we can turn HEAT/COOL on/off)
    ; ==========================================================
    ; TRISD controls whether PORTD pins are inputs(1) or outputs(0).
    ; We want outputs because we are driving HEAT/COOL systems.
    banksel TRISD
    clrf    TRISD            ; PORTD = outputs
    banksel PORTD
    clrf    PORTD            ; start with everything OFF

    ; ==========================================================
    ; STEP B: PUT EXAMPLE TEMPERATURES INTO RAM
    ; ==========================================================
    ; Change these values when you test different cases.
    ; Example:
    ;   0x0F = 15 decimal
    ;   0x14 = 20 decimal
    movlw   0x0F              ; ref temp (goal) = 15
    movwf   refTempReg
    movlw   0x14              ; measured temp (current) = 20
    movwf   measTempReg

; ==============================================================
; STEP C: DECISION MAKING (THIS IS THE ?IF/ELSE? PART)
; ==============================================================
; Goal:
;   measured > ref  -> COOL
;   measured < ref  -> HEAT
;   measured = ref  -> OFF
;
; Extra rule:
;   If measured is negative, treat it as "too cold" -> HEAT
; ==============================================================

CheckRangeAndCompare:

    ; 1) NEGATIVE CHECK:
    ; If measTempReg is negative, bit7 will be 1.
    ; Negative temperature => too cold => HEAT.
    btfsc   measTempReg, 7
    goto    SET_HEAT

    ; 2) COMPARE measured and ref:
    ; This subtracts: (measured - ref)
    ; The CPU sets internal flags after subtraction:
    ;   Z flag = 1 means result is zero => equal
    ;   C flag = 1 means no borrow => measured >= ref
    movf    refTempReg, W
    subwf   measTempReg, W    ; W = measured - ref

    ; If Z flag is 1 => measured == ref
    btfsc   STATUS, 2
    goto    SET_EQUAL

    ; If Carry flag is 1 here (and not equal) => measured > ref
    btfsc   STATUS, 0
    goto    SET_COOL

    ; Otherwise measured < ref
    goto    SET_HEAT

; ==============================================================
; STEP D: STORE THE DECISION (contReg) AND GO DO IT
; ==============================================================
; contReg meaning:
;   0 = perfect temp (OFF)
;   1 = too cold (HEAT)
;   2 = too hot  (COOL)
; ==============================================================

SET_EQUAL:
    clrf    contReg           ; contReg = 0
    goto    LED_OFF

SET_COOL:
    movlw   0x02
    movwf   contReg           ; contReg = 2
    goto    LED_COOL

SET_HEAT:
    movlw   0x01
    movwf   contReg           ; contReg = 1
    goto    LED_HOT

; ==============================================================
; STEP E: TURN ON/OFF THE OUTPUT PINS (HEAT/COOL)
; ==============================================================
; PORTD.1 = HEAT
; PORTD.2 = COOL
; ==============================================================

LED_COOL:
    ; COOL ON, HEAT OFF
    banksel PORTD
    bsf     PORTD,2
    bcf     PORTD,1
    goto    HEX_TO_BCD

LED_HOT:
    ; HEAT ON, COOL OFF
    banksel PORTD
    bsf     PORTD,1
    bcf     PORTD,2
    goto    HEX_TO_BCD

LED_OFF:
    ; both OFF (do nothing)
    banksel PORTD
    bcf     PORTD,1
    bcf     PORTD,2
    goto    HEX_TO_BCD

; ==============================================================
; STEP F: CONVERT BOTH TEMPS INTO DECIMAL DIGITS (BCD style)
; ==============================================================
; Why: the assignment wants the decimal digits stored separately.
; Example: 44 -> hundreds=0, tens=4, ones=4
;
; ref digits go to:  0x62 0x61 0x60
; meas digits go to: 0x72 0x71 0x70
;
; For negative measuredTemp: ignore the minus sign (use absolute value).
; ==============================================================

HEX_TO_BCD:

; ---------- Convert refTempReg to decimal digits ----------
    clrf    count
    movf    refTempReg, W
    movwf   number
    movlw   100

Loop100sRef:
    incf    count, F
    subwf   number, F
    bc      Loop100sRef
    decf    count, F
    addwf   number, F
    movff   count, REF_HUND

    clrf    count
    movlw   10

Loop10sRef:
    incf    count, F
    subwf   number, F
    bc      Loop10sRef
    decf    count, F
    addwf   number, F
    movff   count, REF_TENS
    movff   number, REF_ONES

; ---------- Convert measTempReg to decimal digits (ABS value) ----------
    movf    measTempReg, W
    movwf   number

    ; If number is negative, flip it into positive magnitude:
    ; (~number + 1) = absolute value for two's complement.
    btfss   number, 7
    goto    MEAS_POS
    comf    number, F
    incf    number, F
MEAS_POS:

    clrf    count
    movlw   100

Loop100sMeas:
    incf    count, F
    subwf   number, F
    bc      Loop100sMeas
    decf    count, F
    addwf   number, F
    movff   count, MEA_HUND

    clrf    count
    movlw   10

Loop10sMeas:
    incf    count, F
    subwf   number, F
    bc      Loop10sMeas
    decf    count, F
    addwf   number, F
    movff   count, MEA_TENS
    movff   number, MEA_ONES

    ; END: sit here forever (program finished)
    goto $