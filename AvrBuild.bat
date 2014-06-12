@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "G:\soldeir\station\labels.tmp" -fI -W+ie -C V2E -o "G:\soldeir\station\station.hex" -d "G:\soldeir\station\station.obj" -e "G:\soldeir\station\station.eep" -m "G:\soldeir\station\station.map" "G:\soldeir\station\os.asm"
