; Коды символов для семисегментного индикатора
; индикатор подключается к порту так:
; a b c d e f g DP - сегменты
; 7 6 5 4 3 2 1 0  - биты порта
;
;  a_
; f|g|b
;	-
; e| |c
;   -
;   d 	

.equ Dig0               = 0xFC
.equ Dig1				= 0x60
.equ Dig2				= 0xDA
.equ Dig3				= 0xF2
.equ Dig4               = 0x66
.equ Dig5               = 0xB6
.equ Dig6               = 0xBE
.equ Dig7               = 0xE0
.equ Dig8               = 0xFE
.equ Dig9               = 0xF6

; Загружаем цифры
.MACRO LoadDigits
	LDI ZL, Low(Digits)
	LDI ZH, High(Digits)

    LDI Tmp, Dig0
	ST Z+, Tmp
	LDI Tmp, Dig1
	ST Z+, Tmp
	LDI Tmp, Dig2
	ST Z+, Tmp
	LDI Tmp, Dig3
	ST Z+, Tmp
	LDI Tmp, Dig4
	ST Z+, Tmp
	LDI Tmp, Dig5
	ST Z+, Tmp
	LDI Tmp, Dig6
	ST Z+, Tmp
	LDI Tmp, Dig7
	ST Z+, Tmp
	LDI Tmp, Dig8
	ST Z+, Tmp
	LDI Tmp, Dig9
	ST Z, Tmp
.ENDMACRO

; Декодер температуры
; Преобразует двухбайтное число из SRAM в трехзнаковый код для 7-сегментного индикатора
; аргументы:
;   Temperature - адрес на младший байт числа температуры в SRAM
.MACRO DigitalDecoder
					LDI Counter, 0x00
					; Получаем сотни
					LDI ZL, Low(@0)
					LDI ZH, High(@0)
					LD XL, Z+
					LD XH, Z
	
GetHundreds:	 
					LDI Tmp, High(100) 
					CP Tmp, XH
					BRLO ExtractHundreds
					CPI XL, Low(100)
					BRSH ExtractHundreds

					; извлекаем 100-и
					LDI ZL, Low(Digits)
					LDI ZH, High(Digits)

					ADD ZL, Counter

					LD Tmp, Z

					LDI ZL, Low(Indicator)
					LDI ZH, High(Indicator)

					ST Z, Tmp

					RJMP GetDecimals ; если < 100 то извлекаем 10-и

ExtractHundreds: 
					SUBI XL, Low(100)
					SBCI XH, High(100)
					INC Counter

					RJMP GetHundreds

GetDecimals:        LDI Counter, 0x00

ExtractDecimals:    ; Сохраняем десятки
					LDI ZL, Low(Digits)
					LDI ZH, High(Digits)

					ADD ZL, Counter
					LD Tmp, Z

					LDI ZL, Low(Indicator)
					LDI ZH, High(Indicator)
					STD Z+1, Tmp

					CPI XL, 10
					BRLO ExtractUnits

					SUBI XL, 10
					INC Counter

					RJMP ExtractDecimals
					
ExtractUnits:   	LDI ZL, Low(Digits)
					LDI ZH, High(Digits)

					ADD ZL, XL
					LD Tmp, Z
					LDI ZL, Low(Indicator)
					LDI ZH, High(Indicator)
					 
					STD Z+2, Tmp
.ENDMACRO

.MACRO ADCService
	PUSH ZL
	PUSH ZH
	PUSH XL
	PUSH XH
	IN XL, ADCL
	IN XH, ADCH

	LDI ZL, Low(STemperature)
	LDI ZH, High(STemperature)
	
	ST Z+, XL
	ST Z, XH

	POP XH
	POP XL
	POP ZH
	POP ZL
	RETI
.ENDMACRO
