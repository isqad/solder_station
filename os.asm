.include "m8def.inc"
.include "kernel/macro.asm"

.equ Temperature1 = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.equ TS_Idle = 0		; 

.equ TS_OutDig1 = 1		; 
.equ TS_OutDig2	= 2		; 
.equ TS_OutDig3 = 3		; 

.equ TS_Task4 = 4		;
.equ TS_Task5 = 5		;
.equ TS_Task6 = 6		; 
.equ TS_Task7 = 7		;
.equ TS_Task8 = 8		;
.equ TS_Task9 = 9		;

.def OSREG = R17   ; ������� ������� �������
.def Counter = R18 ; �������
.def Tmp = R20
.def Temp1 = R19   ; ��������

.include "prj/macro.asm"

; RAM ------------------------------

.DSEG

				.equ TaskQueueSize = 11 ; ������ ������� �����
TaskQueue:		.byte TaskQueueSize		; ����������� 11 ���� ��� ����� �������

				.equ TimersPoolSize = 5	; ���������� ��������
TimersPool:		.byte TimersPoolSize*3  ; 15 ���� ��� ��������� ������

STemperature:   .byte 2                 ; ������������� ����������� (��������)
		        .equ DigitsSize = 10    ; ����� ��� ����������
Digits:	        .byte DigitsSize

		        .equ IndicatorSize = 3 ; o?e oeo?u o eiaeeaoi?a
Indicator:      .byte IndicatorSize

; FLASH ----------------------------

.CSEG

; Начало программы 
                .ORG 0x0000
                RJMP Reset

; Таблица прерываний
                .include "vectors.asm"

                .ORG INT_VECTORS_SIZE

; ����������� ����������
OutComp2Int:	TimeService
ReadADC:        ADCService


; Конец таблицы прерываний


; ������������� �����
Reset:          LDI R16, Low(RAMEND)
                OUT SPL, R16

                LDI R16, High(RAMEND)
                OUT SPH, R16


; ������� RAM � ���������
				;.include "clear.asm"

; ����� ���� ������

				UOUT SREG, 0x00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ������������� ��������� � ������� �������


				RCALL ClearTimers
				RCALL ClearTaskQueue

				.equ MainClock = 8000000 ; ���������� ������ ���� �������� �� 8Mhz
				.equ TimerDivider = MainClock/64/1000 ; 1ms

				UOUT TCCR2, 1<<CTC2|4<<CS20 ; ������������� CTC � ������������ 64
				UOUT TCNT2, 0

				LDI OSREG, Low(TimerDivider)
				OUT OCR2, OSREG

				UOUT TIMSK, 1<<OCF2

; Отключаем компаратор
				LDI OSREG, 1<<ACD
				OUT ACSR, OSREG

				; ������ ���
				UOUT ADCSRA, 1<<ADEN|1<<ADIE|1<<ADPS2|1<<ADPS0|1<<ADPS1
				UOUT ADMUX, 1<<REFS0|0<<MUX0|0<<MUX1|0<<MUX2|0<<MUX3


; ��������� ������
				UOUT DDRD, 0xFF
				UOUT PORTD, 0x00
				
				; ���� D - ����� ����� 0, 1 � 4
				UOUT DDRC, (1<<PC3|1<<PC4|1<<PC5)
				UOUT PORTC, (0<<PC3|0<<PC4|0<<PC5)
				
; �������� �������� �����������
				CLI
				LDI ZL, Low(STemperature)
				LDI ZH, High(STemperature)

				LDI XL, Low(Temperature1)
				LDI XH, High(Temperature1)

				ST Z+, XL
				ST Z, XH
				
				LoadDigits ; ��������� �����
		
				DigitalDecoder STemperature
				SEI

; ������� ��������
Background:		SetTimerTask TS_Task4, 100
				SetTimerTask TS_Task5, 1000
				RCALL OutDig1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ������� ����
; ��������� ����������
MainLoop:		SEI
				WDR ; ������ ������
				RCALL ProcessTaskQueue ; ��������� ������� �����
				RCALL Idle             ; ������� ����
				RJMP MainLoop

; ������ �����

Idle:			RET
OutDig1:		
				PUSH ZL
				PUSH ZH
				PUSH Temp1
				
				LDI ZL, Low(Indicator)
				LDI ZH, High(Indicator)
				
				UOUT PORTC, (0<<PC3|0<<PC4|1<<PC5)
				LD Temp1, Z
				OUT PORTD, Temp1

				POP Temp1
				POP ZH
				POP ZL
				
				SetTimerTask TS_OutDig2, 60
				RET
OutDig2:		
				PUSH ZL
				PUSH ZH
				PUSH Temp1				

				LDI ZL, Low(Indicator)
				LDI ZH, High(Indicator)
				
				UOUT PORTC, (0<<PC3|1<<PC4|0<<PC5)
				LDD Temp1, Z+1
				OUT PORTD, Temp1

				POP Temp1
				POP ZH
				POP ZL

				SetTimerTask TS_OutDig3, 60
				RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OutDig3:		
				PUSH ZL
				PUSH ZH
				PUSH Temp1

				LDI ZL, Low(Indicator)
				LDI ZH, High(Indicator)
				
				UOUT PORTC, (1<<PC3|0<<PC4|0<<PC5)
				
				LDD Temp1, Z+2
				OUT PORTD, Temp1

				POP Temp1
				POP ZH
				POP ZL

				SetTimerTask TS_OutDig1, 60

				RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Task4:			PUSH ZL
				PUSH ZH
				PUSH XL
				PUSH XH
				PUSH Counter
				PUSH Tmp
				
				CLI
				DigitalDecoder STemperature
				SEI

				POP Tmp
				POP Counter
				POP XH
				POP XL
				POP ZH
				POP ZL

				SetTimerTask TS_Task4, 200
				RET
;;;;;;;;;;;;;;;;;;;;;;��������� ������ � ���
Task5:			
				PUSH ZL
				PUSH ZH
				PUSH XL
				PUSH XH
				
				SBI ADCSRA, ADSC

				POP XH
				POP XL
				POP ZH
				POP ZL
				
				SetTimerTask TS_Task5, 1000 ; ������ ������� ������ ���������
				RET
Task6:			RET
Task7:			RET
Task8:			RET
Task9:			RET


; ����
				.include "kernel.asm"

; ������� ���������
TaskProcs:      .dw Idle
				.dw OutDig1
				.dw OutDig2
				.dw OutDig3
				.dw Task4
				.dw Task5
				.dw Task6
				.dw Task7
				.dw Task8
				.dw Task9
		
; EEPROM ---------------------------

.ESEG
