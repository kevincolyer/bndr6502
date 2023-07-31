;--------------------------------------------
; memory map for BNDR6502
;--------------------------------------------

;--------------------------------------------
; where to load bootloader (note 4k limit!)
;--------------------------------------------

userZp          = $00
osZp            = $80
hwStack         = $100
osInputBuffer   = $200
osOutputBuffer  = $300
osVariables     = $400
osUserCmdTable  = $500          ; only allow 256 bytes for this.

fat32_workspace = $600          ; page aligned 512 byte workspace
userLowMem      = $800

userStart       = $1000
userLowMemEnd   = userStart-1
romStart        = $8000
osStart         = romStart      ; entry for all calls to os
userEnd         = osStart-1
osEnd           = ioSpace-1




;--------------------------------------------
; assign zero page area for os
;--------------------------------------------
        .dsect
        .org    osZp

osError:
        byt
osWarmBootFlag:
        byt
osSoftIrqVector:
        wrd
osSoftNmiVector:
        wrd
osSoftResetVector:
        wrd
osR0:
        wrd
osR1:
        wrd
osR2:
        wrd
osR3:
        wrd
osR4:
        wrd

osCallArg0:
        wrd
osCallArg1:
        wrd
osCallArg2:
        wrd
osCallArg3:
        wrd

        ; extra registers for use in kernal
R0:
        wrd
R1:
        wrd
R2:
        wrd
m_working:
        wrd
os_in_testing_mode:             ; set to $ff to indicate testing
        byt



zp_sd_address:
        wrd
zp_sd_currentsector:
        blk     4               ;4 bytes
zp_fat32_general_pointer:       ; see libfat32.inc
        blk     2

osEndOfLowMem:                  ; intended to use to mark end point of low mem - planned for dynamic expansion
        wrd
osLastZp:                       ;used as a marker for where the last allocated os zp items are...
        byt
        ;osRTC
        .dend


; -----------------------
; general variables that do not need to be in zp
        .dsect
        .org    osVariables

osOutputBufferLen:
        byt
osInputBufferLen:
        byt
osRandomSeed:
        wrd
osRandomWord:
        wrd

; Reserve 4 bytes of RAM variable space for a 32-bit centisecond counter.
; This record rolls over about every 471 days.  It is to ease calculation
; of times and alarms that could cross irrelevant calendar boundaries.
; Byte order is low byte first, high byte last.


os_rtc_cs_32:
        wrd
        wrd
os_rtc_countdown:               ; two byte countdown timer
        wrd

os_rtc_CENTISEC:
        byt                     ;for the time-of-day (TOD) variables.
os_rtc_SECONDS:
        byt                     ; Reserve one byte of RAM variable space for each of these numbers.
os_rtc_MINUTES:
        byt                     ; At power-up, it's likely these numbers will make an invalid date
os_rtc_HOURS:
        byt                     ; not just an incorrect date.  You might want to initialize them to
os_rtc_DAY:
        byt                     ; a date that at least makes sense, like midnight 1/1/04.
os_rtc_MONTH:
        byt
os_rtc_YEAR:
        byt
os_rtc_CENTURY:
        byt
os_rtc_set:
        byt
os_rtc_DOW:                     ; in the init code this marks last entry to zero
        byt

; i2c reseve 6 bytes
i2c_v_started:
        byt                     ; osvariable space
i2c_v_error_code:
        byt
i2c_v_byte:
        byt                     ; used for shifting bits in and out
i2c_v_flags:
        byt                     ; flag storage
i2c_v_bit:
        byt                     ; bit storage
i2c_v_lcd_instruction:
        byt                     ; tempstorage for lcd instruction

zp_fat32_variables:             ; 24 bytes
        blk     24

rtc_hex_temp:
        byt

rtc_reading:
rtc_reading_hh:
        byt
rtc_reading_mm:
        byt
rtc_reading_ss:
        byt
rtc_reading_dd:
        byt
rtc_reading_mo:
        byt
rtc_reading_yy:
        byt
rtc_reading_cc:
        byt
rtc_reading_dow:
        blk     3

subdirname:                     ; used in os_file_functions.inc
        blk     14
filename:
        blk     14
        byt                     ; just in case
os_file_error:
        byt
dizzybox_init_ok:               ; > 0 is NOT initialised ok.
        byt
dizzybox_case_insensitive:      ; 0 case in sensitive 1 sensitive (default 0 in dizzybox_init)
        byt

        .dend

;--------------------------------------------
; IO device access
;--------------------------------------------

ioSpace         = $FE00         ; 11111110 upper byte

; 8 devices total seperated by $20 bytes
Device0         = ioSpace
Device1         = ioSpace+$20
Device2         = ioSpace+$40
Device3         = ioSpace+$60
Device4         = ioSpace+$80
Device5         = ioSpace+$A0
Device6         = ioSpace+$C0
Device7         = ioSpace+$E0

;--------------------------------------------
; IO device assignments
;--------------------------------------------

ACIA0           = Device0       ;serial port R6551 uart
VIA0            = Device1       ;r65c22 versatile io via
