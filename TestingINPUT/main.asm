;********************************************
; * Binary Calculator *
; * CAL1 assignment *
; * (C)2017 by Christoffer Thygesen *
; ********************************************
;
; Included header file for target AVR type
.INCLUDE "M2560DEF.INC"
;
; ============================================
; H A R D W A R E I N F O R M A T I O N
; ============================================
;
; http://www.atmel.com/Images/Atmel-2549-8-bit-AVR-Microcontroller-ATmega640-1280-1281-2560-2561_datasheet.pdf
; this one, atmel2560
;
; ============================================
; P O R T S A N D P I N S
; ============================================
;
; B is switches, D is LEDs
; PORTB is connected to switches
; PORTD is connected to LEDs
;
; ============================================
; C O N S T A N T S T O C H A N G E
; ============================================
;
; [Add all constants here that can be subject
; to change by the user]
; Format: .EQU const = $ABCD
;
; ============================================
; F I X + D E R I V E D C O N S T A N T S
; ============================================
;
; [Add all constants here that are not subject
; to change or calculated from constants]
; Format: .EQU const = $ABCD
;
; ============================================
; R E G I S T E R D E F I N I T I O N S
; ============================================
;
.def delay1	= r17	;used in delay routine
.def delay2	= r18	;used in delay routine
.def delayv	= r19	;variable in delay routine

.def value1 = R21	;records the first typed value
.def value2 = R22	;records the second typed value
.def sum = R23		;used for sum in the arithmetic answer
;
; ============================================
; S R A M D E F I N I T I O N S
; ============================================
;
; Format: Label: .BYTE N ; reserve N Bytes from Label:
;
; ============================================
; R E S E T A N D I N T V E C T O R S
; ============================================
;
;
; ============================================
; I N T E R R U P T S E R V I C E S
; ============================================
;
; [Add all interrupt service routines here]
;
; ============================================
; M A I N P R O G R A M I N I T
; ============================================
;
; ============================================
; P R O G R A M L O O P
; ============================================

	rjmp main

delay:

	LDI delay1, 6
	LDI delay2, 19
	LDI delayv, 175

/*	clr	delay1
	clr	delay2
	ldi	delayv, 10*/
	;3 cycles
      
delay_loop: 
	DEC delayv
	BRNE delay_loop
	DEC delay2
	BRNE delay_loop
	DEC delay1
	BRNE delay_loop
	RET
	;1000000 cycles

/*
	dec	delay2		
	brne	delay_loop 	
	dec	delay1		
	brne	delay_loop 	
	dec	delayv		
	brne	delay_loop 	
	ret     		; go back to where we came from*/

main:
	CLR value1
	CLR value2
	CLR sum	
	LDI R20, 0xFF				;Initialize PORTD as output port
	OUT DDRD, R20				;Make PORTD to output, LEDs
	LDI R20, 0x00				;Initialize PORTB as input
	OUT DDRB, R20				;Make PORTB to input, switches
	rjmp read1					;Start the actual program
	;9 cycles

SAVE1:
	MOV value1, R20				;Copy value in R20 to value1 (our first value for our calculator)
	LDI R20, 0x00				;"reset" R20 by making it 0x00
	LDI R29, 0xFF				;R29 is used to display on LEDs, so they are turned off when R29 is 0xFF
	rjmp read2					;let's start collecting the second number
	;5 cycles

read1:
	IN R25, PINB				;Read switches
	CALL delay					;delay to help with button stutters
	OUT PORTD, R29				;take value in R29 and show it on LEDs
	COM R25						;1's compliment on R25
	CPI R25, 0x80				;Compares R25 to 0b1000 0000
	BRSH SAVE1					;if bit 0x80 pressed, go to SAVE1 else keep going
	OR R20, R25					;Performs logic gate OR to R20 and R25
	COM R20						;1's compliment on R20
	MOV R29, R20				;Copies value of R20 into R29
	COM R20						;1's compliment on R20
	rjmp read1					;Jump back up to read1
	;14 cycles if BRSH is false, 9 if true

SAVE2:
	MOV value2, R20				;copy value from R20 to value2
	LDI R20, 0x00				;Reset R20
	LDI R29, 0xFF				;Reset R29
	rjmp saveoperation			;jump to saveoperation, to select how these two numbers should add together
	;5 cycles

read2:
	IN R25, PINB				;read switches
	CALL delay					;call delay to help with button stutters
	OUT PORTD, R29				;take value from R29 and show it on LEDs
	COM R25						;1's compliment on R25
	CPI R25, 0x80				;compares R25 to 0b1000 0000
	BRSH SAVE2					;if bit 0x80 is pressed, go to SAVE2 else keep going down
	OR R20, R25					;performs logic gate or to R20 and R25
	COM R20						;1's compliment on R20
	MOV R29, R20				;copy value from R20 to R29
	COM R20						;1's compliment on R20
	rjmp read2					;start over the read2
	;14 cycles if BRSH is false, 9 if true

saveoperation:
	IN R25, PINB				;read switches
	LDI R29, 0xF0				;Load R29 0xF0
	OUT PORTD, R29				;Light up LED 0000 1111 to show how far in the progress you are.
								;These 4 lit LEDs does something different, either add, subtract, divide or multiply

	CALL delay					;call delay to help with stutters
	CPI R25, 0b11111110			;compare R25 with the binary number
	BREQ addition				;jump to addition
	CPI R25, 0b11111101			;compare R25 with the binary number
	BREQ subtraction			;jump to subtraction
	CPI R25, 0b11111011			;compare R25 with the binary number
	BREQ multiplication			;jump to multiplication
	CPI R25, 0b11110111			;compare R25 with the binary number
	BREQ division				;jump to division
	LDI R25, 0x00				;if user pressed either of the 4 other switches not in use, set the register to 0x00 and next operation restarts the routine
	rjmp saveoperation			;restart routine from the top
	;17 cycles if it goes the whole way down or 9, 11, 13 or 15 depending what is pressed

addition:
	MOV SUM, value1				;copy value1 into SUM
	ADD SUM, value2				;add value2 into SUM
	COM SUM						;1's compliment SUM
	out PORTD, SUM				;take SUM out to the LEDs
	rjmp end					;go to end (finish)
	;6 cycles

subtraction:	
	MOV SUM, value1				;I changed the code from using SUB
	COM value2					;to using 2's compliment instead
	INC value2
	ADD SUM, value2
	COM SUM
	OUT PORTD, SUM
	rjmp end
	;8 cycles

/*	MOV SUM, value1				;copy value1 into SUM
	SUB SUM, value2				;subtract value2 from SUM
	COM SUM						;1's compliment SUM
	out PORTD, SUM				;take SUM out to the LEDs
	rjmp end					;go to end (finish)*/
	;6 cycles (so this one is faster)

multiplication:
	MUL value1, value2			;multiply value1 and value2
	COM R0						;1's compliment R0
	OUT PORTD, R0				;take R0 out to the LEDs
	rjmp end					;go to end (finish)
	;6 cycles

divisionbody:
	INC SUM						;increment count
	SUB value1, value2			;subtract value2 from value1

division:
	CP value1, value2			;compare value1 and value2
	BRGE divisionbody			;branch to divisionbody if greater or equel
	COM SUM						;1's compliment count
	OUT PORTD, SUM				;take count out to the LEDs
	;if BRGE = false it's 4 cycles, else it's gonna run it x times before it is, each run is 5 cycles. So 5 * x + 4 where x is where BRGE = true

end:
	rjmp end					;end of program