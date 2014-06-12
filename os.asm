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

.def OSREG = R17   ; Рабочий регистр системы
.def Counter = R18 ; Счетчик
.def Tmp = R20
.def Temp1 = R19   ; Мусорник

.include "prj/macro.asm"

; RAM ------------------------------

.DSEG

				.equ TaskQueueSize = 11 ; Размер очереди задач
TaskQueue:		.byte TaskQueueSize		; Резервируем 11 байт для нашей очереди

				.equ TimersPoolSize = 5	; Количество таймеров
TimersPool:		.byte TimersPoolSize*3  ; 15 байт для таймерной службы

STemperature:   .byte 2                 ; Установленная температура (кнопками)
		        .equ DigitsSize = 10    ; Цифры для индикатора
Digits:	        .byte DigitsSize

		        .equ IndicatorSize = 3 ; o?e oeo?u o eiaeeaoi?a
Indicator:      .byte IndicatorSize

; FLASH ----------------------------

.CSEG

; РќР°С‡Р°Р»Рѕ РїСЂРѕРіСЂР°РјРјС‹ 
                .ORG 0x0000
                RJMP Reset

; РўР°Р±Р»РёС†Р° РїСЂРµСЂС‹РІР°РЅРёР№
                .include "vectors.asm"

                .ORG INT_VECTORS_SIZE

; Обработчики прерываний
OutComp2Int:	TimeService
ReadADC:        ADCService


; РљРѕРЅРµС† С‚Р°Р±Р»РёС†С‹ РїСЂРµСЂС‹РІР°РЅРёР№


; Инициализация стека
Reset:          LDI R16, Low(RAMEND)
                OUT SPL, R16

                LDI R16, High(RAMEND)
                OUT SPH, R16


; Очистка RAM и регистров
				;.include "clear.asm"

; Сброс всех флагов

				UOUT SREG, 0x00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Инициализация переферии и таймера системы


				RCALL ClearTimers
				RCALL ClearTaskQueue

				.equ MainClock = 8000000 ; Контроллер должен быть настроен на 8Mhz
				.equ TimerDivider = MainClock/64/1000 ; 1ms

				UOUT TCCR2, 1<<CTC2|4<<CS20 ; Устанавливаем CTC и предделитель 64
				UOUT TCNT2, 0

				LDI OSREG, Low(TimerDivider)
				OUT OCR2, OSREG

				UOUT TIMSK, 1<<OCF2

; РћС‚РєР»СЋС‡Р°РµРј РєРѕРјРїР°СЂР°С‚РѕСЂ
				LDI OSREG, 1<<ACD
				OUT ACSR, OSREG

				; Запуск АЦП
				UOUT ADCSRA, 1<<ADEN|1<<ADIE|1<<ADPS2|1<<ADPS0|1<<ADPS1
				UOUT ADMUX, 1<<REFS0|0<<MUX0|0<<MUX1|0<<MUX2|0<<MUX3


; Настройка портов
				UOUT DDRD, 0xFF
				UOUT PORTD, 0x00
				
				; Порт D - берем ножки 0, 1 и 4
				UOUT DDRC, (1<<PC3|1<<PC4|1<<PC5)
				UOUT PORTC, (0<<PC3|0<<PC4|0<<PC5)
				
; Загрузим тестовую температуру
				CLI
				LDI ZL, Low(STemperature)
				LDI ZH, High(STemperature)

				LDI XL, Low(Temperature1)
				LDI XH, High(Temperature1)

				ST Z+, XL
				ST Z, XH
				
				LoadDigits ; загружаем цифры
		
				DigitalDecoder STemperature
				SEI

; Фоновые действия
Background:		SetTimerTask TS_Task4, 100
				SetTimerTask TS_Task5, 1000
				RCALL OutDig1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Главный цикл
; Резрешаем прерывания
MainLoop:		SEI
				WDR ; Гладим собаку
				RCALL ProcessTaskQueue ; Обработка очереди задач
				RCALL Idle             ; Простой ядра
				RJMP MainLoop

; Секция Задач

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
;;;;;;;;;;;;;;;;;;;;;;Симуляция чтения с АЦП
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
				
				SetTimerTask TS_Task5, 1000 ; каждую секунду делаем измерение
				RET
Task6:			RET
Task7:			RET
Task8:			RET
Task9:			RET


; Ядро
				.include "kernel.asm"

; Таблица переходов
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
