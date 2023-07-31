; ROM for BNDR6520
; Short rom that uses serial port loader that downloads
; XMODEM encoded programe in .o64 format (C64 programs - see comments below)
;
; BNDR6502 uses VIA6551 at iospace $FE00

        .include "os_macro_general.inc"
        .include "os_memorymap.inc"
        .include "os_constants.inc"
        ;.include "os_calls.inc"


; macro for printing z string
; OS INTERNAL only

        .macro  macro_putz,zstring
        ldx     #<\zstring
        ldy     #>\zstring
        jsr     ACIA_putZ_XY
        .endm

        .macro  macro_putz_safe,zstring
        phy
        phx
        ldx     #<\zstring
        ldy     #>\zstring
        jsr     ACIA_putZ_XY
        plx
        ply
        .endm

        ; kernal version simple print one char
        .macro  k_macro_print_c,char
        lda     #\char
        jsr     ACIA_putc
        .endm

; HARDWARE rom vectors
;
        *=      $fffa
        .word   nmi
        .word   reset
        .word   irq


;===============================================
;               START of OS ROM
;===============================================
; conditional compile for symon virtual cpu

; compile with -Dsymon
; compile with -Dnolcd to disable lcd code

; make sure symon is in 65c02 mode!!!!!!!! or some opcodes don't work
        .org    romStart


; to call into os
; x - holds index (always even)
; a - anything
; y - anything (trys to preserve)
; carry -> clear = failure, set = success
; osCallR0 - zp word - if needed
; osCallR1 - zp word - if needed
; invalidates ALL registers: save before using



osCallDispatch:
        clc                     ;
        jmp     (osCallVectorTable,x)

        ;===============================================
        ;       USERSPACE CALLABLE ROUTINES
        ;===============================================


osCallVectorTable:
        ;0
        .word   ACIA_putc
        ;2
        .word   ACIA_getc       ; for indirection... (y will be preserved)
        ;4
        .word   ACIA_putZ_XY    ; puts a 0 terminated message - x = lo byte, y =hi byte
        ;6
        .word   ACIA_putc_CRLF  ; output CR and LF
        ;8
        .word   CLEAR_OS_OUTPUT_BUF
        ;10
        .word   PUT_OS_OUTPUT_BUF; print 0 terminated os output buffer
        ;12
        .word   PUSH_BYTE_TO_OS_OUTPUT_BUF
        ;14
        .word   CMP_STRING_WITH_OS_OUTPUTBUF
        ;16
        .word   m_prompt        ; jump back into monitor (warm) NOTE JUMP!!!!
        ;18
        .word   ACIA_putc_hex_byte
        ;20
        .word   ACIA_putZ_osCallArg0; puts a 0 terminated message - osCallArg0
        ;22
        .word   CLEAR_OS_INPUT_BUF
        ;24
        .word   osLineEditInputBuf
        ;26
        .word   osWord2DecimalString
        ;28
        .word   osZStrCopy
        ;30
        .word   m_add_user_cmd
        ;32
        .word   bin2bcd

        .string "BNDR Rom"

;;;;AUTOEXPORT romStart 100 os_jmp_table.inc
        .org    romStart+$100
os_i2c_release:
        jmp     i2c_release
os_i2c_read_byte:
        jmp     i2c_read_byte
os_i2c_stop_cond:
        jmp     i2c_stop_cond
os_i2c_write_byte:
        jmp     i2c_write_byte
os_i2c_init:
        jmp     i2c_init
os_i2c_wait10ms:
        jmp     i2c_wait10ms

os_rtc_get_i2c:
        jmp     k_rtc_get_i2c
os_rtc_set_i2c:
        jmp     k_rtc_set_i2c
os_date_get:
        jmp     k_date_get
os_date_set:
        jmp     k_date_set
os_time_get:
        jmp     k_time_get
os_parse_set_date:
        jmp     k_parse_set_date
os_print_date_time:
        jmp     k_print_date_time

os_SPI_init:
        jmp     k_SPI_init
os_SPI_Send_Byte:
        jmp     k_SPI_Send_Byte
os_SPI_Recv_Byte:
        jmp     k_SPI_Recv_Byte
os_SPI_Pump_CLK:
        jmp     k_SPI_Pump_CLK
os_SPI_Write_Read_Byte:
        jmp     k_SPI_Write_Read_Byte

os_sd_init:
        jmp     sd_init
os_sd_readsector:
        jmp     sd_readsector
os_sd_sendcommand:
        jmp     sd_sendcommand

os_fat32_open_root_dir:
        jmp     k_fat32_open_root_dir
; os_fat32_open_dir:
;         jmp     k_fat32_open_dir
os_fat32_find_open_dir_ent:
        jmp     k_fat32_find_open_dir_ent
os_fat32_iterate_dir:
        jmp     k_fat32_iterate_dir
os_fat32_open_file:
        jmp     k_fat32_open_file
os_fat32_load_file:
        jmp     k_fat32_load_file
os_fat32_read_byte:
        jmp     k_fat32_read_byte
os_fat32_write_file:
        jmp     k_fat32_write_file
os_fat32_close_file:
        jmp     k_fat32_close_file
os_executable_load:
        jmp     k_executable_load
os_executable_relocate:
        jmp     k_executable_relocate
os_executable_run:
        jmp     k_executable_run
os_fat32_valid_filename_chars:
        jmp     k_fat32_valid_filename_chars
; os_fat32_is_filename_valid:
;         jmp     k_fat32_is_filename_valid
os_fat32_is_valid_filename_char:
        jmp     k_fat32_is_valid_filename_char

;
; os_fat32_open_dir:
; os_fat32_open_file:
; os_fat32_read_file:
; os_fat32_write_file:
; os_fat32_close_file:
;
; os_executable_load:
; os_executable_relocate:
; os_executable_run:
; os_malloc:
; os_free:
; os_zp_malloc:
; os_zp_free:

os_is_decimal:
        jmp     k_is_decimal

;;;;AUTOEXPORTEND




        ;===============================================
        ;       OS RESET AND INTERRUPT VECTORS
        ;===============================================

reset:
        jmp     osBootStrap


        ; Version flag
msg_version:
        ifdef   symon
        .byte   "(-Dsymon) "
        endif
        ifdef   nolcd
        .byte   "(-Dnolcd) "
        endif
        .byte   "v1.0.1",CR,LF,0

;===============================================
;       COLD BOOT / RESET ENTRY POINT
;===============================================
osBootStrap:
        ; initialise processor following hardware RESET
        sei                     ; disable interrupts for now
        cld                     ; clear decimal mode
                                ; in an unspecified state on reset otherwise
        ldx     #$FF            ; init stack
        txs

;; INITIALISE HARDWARE
        stz     os_in_testing_mode; not in testing mode
        jsr     ACIA_Init       ; initiailise serial port
        jsr     k_SPI_init
        jsr     i2c_init
        ;===============================================
        ;       test for 65C02!!!
        ;===============================================
        bra     .setup_cont     ; invalid 6502 opcode
        macro_putz msg_not_6502 ; error message - not 6502!

.setup_cont:
; TODO set up ZP vectors for interrupts if that is wanted...

        lda     #<irq_builtin
        sta     osSoftIrqVector
        lda     #>irq_builtin
        sta     osSoftIrqVector+1

        jsr     RTC_SETUP       ; set clock up and start ticking!
        cli                     ; enable interrupts





; init buffers
        jsr     CLEAR_OS_OUTPUT_BUF
        stz     osInputBuffer
        stz     osInputBufferLen; byte pointer to page aligned buffer
        stz     osUserCmdTable  ; set end of table marker for user commands to monitor

        ; current end of Bootstrapping!

; print banners
        macro_putz osvt_fgbg_reset
        macro_putz osvt_cls
        macro_putz osvt_home

        macro_putz msg_banner
        macro_putz msg_version
        macro_putz msg_banner2

;       set clock time from RTC (try 3 times)
        ldy     #3
.rtc_loop:
        jsr     k_rtc_get_i2c
        bcc     .rtc_ok
        dey
        bne     .rtc_loop
        macro_putz msg_rtc_clock_error
        bra     .sd_init
.rtc_ok:
        jsr     k_print_date_time

;       sd card detected?
.sd_init:
        jsr     os_sd_init
        bcc     .sd_ok
        macro_putz msg_sd_not_detected
        bra     .setup_done
.sd_ok:
        macro_putz msg_sd_dectected
        jsr     dizzybox_init
.setup_done:
;===============================================
;       Mainloop
;===============================================

MAINLOOP:
        jmp     MONITOR

;===============================================
;       OS Routines
;===============================================

        .include "device_uart.inc"
        .include "device_spi.inc"
        .include "libsd.inc"
        .include "device_i2c.inc"
        .include "os_xmodem_protocol.inc"
        .include "os_monitor.inc"
        .include "os_snake.inc"
        .include "os_vt102.inc"
        .include "os_utils.inc"
        .include "os_interrupt_service_routines.inc"
        .include "os_date_time.inc"
        .include "os_file_functions.inc"
        .include "libfat32.inc"
        .include "os_dizzybox.inc"

;===============================================
;       VARIOUS STRINGS
;===============================================


msg_banner:
        .byte   ESC,"[36mBNDR6502 project ",ESC,"[0m",0; cyan
msg_banner2:
        .byte   "Bite my ",ESC,"[44mshiny",ESC,"[40m metal breadboard", CR, LF, CR, LF,0
msg_not_6502:
        .byte   "error - compiled for 65C02 but running on 6502",CR,LF,0
msg_sd_dectected:
        .string "SD card detected",CR,LF
msg_sd_not_detected:
        .string "error - SD card not detected",CR,LF
msg_rtc_clock_error:
        .string "error - Real Time Clock not available",CR,LF
