k_date_get:
        phx
        phy
        lda     os_rtc_DAY
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte
        lda     #'/'
        jsr     ACIA_putc

        lda     os_rtc_MONTH
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte
        lda     #'/'
        jsr     ACIA_putc

        lda     os_rtc_YEAR
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte

        lda     #SPACE
        jsr     ACIA_putc

        clc
        lda     os_rtc_DOW
        asl
        adc     os_rtc_DOW
        tax
        ldy     #3
.print_dow:
        lda     dow_table,x
        phx
        jsr     ACIA_putc
        plx
        inx
        dey
        bne     .print_dow
        ply
        plx
        rts



k_time_get:
        lda     os_rtc_HOURS
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte
        lda     #':'
        jsr     ACIA_putc

        lda     os_rtc_MINUTES
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte
        lda     #':'
        jsr     ACIA_putc

        lda     os_rtc_SECONDS
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte

        rts

k_print_date_time:
        macro_store_symbol2word rtc_date_msg,osCallArg0
        jsr     ACIA_putZ_osCallArg0

        jsr     k_time_get

        lda     #SPACE
        jsr     ACIA_putc

        jsr     k_date_get

        jsr     ACIA_putc_CRLF
        rts

;READ GET
;--------------------------------------------------
; 02h  VL_seconds      VL  <seconds 00 to 59 coded in BCD>
; 03h  minutes         x  <minutes 00 to 59 coded in BCD>
; 04h  hours           x  x  <hours 00 to 23 coded in BCD>
; 05h  days            x  x  <days 01 to 31 coded in BCD>
; 06h  weekdays        x  x  x  x  x  <weekdays 0 to 6 in BCD>
; 07h  century_months  C  x  x  <months 01 to 12 coded in BCD>
; 08h  years  <years 00 to 99 coded in BCD>
RTCID=$51                       ; the i2c bus address of rtc clock device




k_rtc_get_i2c:
        phy

        macro_i2c_write_to RTCID,.rtc_i2c_error,$02,-1,-1,-1; ask to read from reg $02

        macro_i2c_read_to_nack RTCID,.rtc_i2c_error,rtc_reading,7,1;read 7 bytes and finish with nack and stop


        ; mask off valitidy bit on seconds
        lda     rtc_reading
        and     #$7f
        ; swap seconds and hours
        pha
        lda     rtc_reading+2
        sta     rtc_reading
        pla
        sta     rtc_reading+2
        ; move dow to end
        lda     rtc_reading+4
        sta     rtc_reading+7
        ; move months to dow slot
        lda     rtc_reading+5
        and     #$7f            ; mask of century bit
        sta     rtc_reading+4
        ; set century
        lda     #$20
        bit     rtc_reading+5
        bpl     .c21
        lda     #$19
.c21:
        sta     rtc_reading+5

        ; set internal clock
        jsr     k_date_set

        clc
        ply
        rts

.rtc_i2c_error:
        pha
        jsr     os_i2c_stop_cond
        pla
        jsr     ACIA_putc_hex_byte
        macro_store_symbol2word rtc_err_msg,osCallArg0
        jsr     ACIA_putZ_osCallArg0

        sec
        ply
        rts

; transfer rtc to internal clock
k_date_set:
        sei
        lda     rtc_reading+2
        jsr     bcd2bin
        sta     os_rtc_SECONDS

        lda     rtc_reading+1
        jsr     bcd2bin
        sta     os_rtc_MINUTES

        lda     rtc_reading
        jsr     bcd2bin
        sta     os_rtc_HOURS

        lda     rtc_reading+3
        jsr     bcd2bin
        sta     os_rtc_DAY

        lda     rtc_reading+4
        jsr     bcd2bin
        sta     os_rtc_MONTH

        lda     rtc_reading+6
        jsr     bcd2bin
        sta     os_rtc_YEAR

        lda     rtc_reading+5
        jsr     bcd2bin
        sta     os_rtc_CENTURY

        lda     rtc_reading+7
        jsr     bcd2bin
        sta     os_rtc_DOW
        lda     #1
        sta     os_rtc_set
        cli
        rts

k_parse_set_date:
        macro_store_symbol2word rtc_set_date_msg,osCallArg0
        jsr     ACIA_putZ_osCallArg0

        jsr     CLEAR_OS_INPUT_BUF
        lda     #80
        sta     osCallArg0
        jsr     osLineEditInputBuf

        ; parse to rtc reading
        ldx     #0              ; index to oscCLEAR_OS_INPUT_BUF
        ldy     #0              ; (read counter 7)
.parse:
        lda     osInputBuffer,x ; upper nybble byte 1
        beq     .parse_error
        jsr     k_is_decimal
        cmp     #$ff
        beq     .parse_error
        asl
        asl
        asl
        asl
        sta     rtc_hex_temp

        inx
        lda     osInputBuffer,x ; lower nybble byte 2
        beq     .parse_error
        jsr     k_is_decimal
        cmp     #$ff
        beq     .parse_error
        ora     rtc_hex_temp
        sta     rtc_reading,y

        inx
        cpy     #7
        beq     .skip_final_delim
        lda     osInputBuffer,x ; delim :
        beq     .parse_error
        cmp     #":"
        bne     .parse_error

        inx
        iny
        cpy     #8
        bne     .parse          ;keep going!
        bra     .skip_final_delim

.parse_error:
        txa
        jsr     bin2bcd
        jsr     ACIA_putc_hex_byte
        macro_store_symbol2word rtc_syntax_error,osCallArg0
        jsr     ACIA_putZ_osCallArg0
        sec
        rts

.skip_final_delim:
        ; process
        lda     rtc_reading_cc  ; century
        cmp     #$19
        bne     .skip_process_cc
        lda     rtc_reading_mo
        ora     #$80            ; set high bit
        sta     rtc_reading_mo
.skip_process_cc:
        clc
        rts


; SET---------------------------------------------------------------
;--------------------------------------------------
; 02h  VL_seconds      VL  <seconds 00 to 59 coded in BCD>
; 03h  minutes         x  <minutes 00 to 59 coded in BCD>
; 04h  hours           x  x  <hours 00 to 23 coded in BCD>
; 05h  days            x  x  <days 01 to 31 coded in BCD>
; 06h  weekdays        x  x  x  x  x  <weekdays 0 to 6 in BCD>
; 07h  century_months  C  x  x  <months 01 to 12 coded in BCD>
; 08h  years  <years 00 to 99 coded in BCD>

k_rtc_set_i2c:
        jsr     k_parse_set_date
        bcc     .ok
        rts
.ok
        ;set the clock
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$02,rtc_reading_ss
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$03,rtc_reading_mm
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$04,rtc_reading_hh
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$05,rtc_reading_dd
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$06,rtc_reading_dow
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$07,rtc_reading_mo
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$08,rtc_reading_yy

        jmp     k_rtc_get_i2c   ; finish by reading the new time set

.rtc_i2c_error:
        pha
        jsr     os_i2c_stop_cond
        pla
        jsr     ACIA_putc_hex_byte
        macro_store_symbol2word rtc_err_msg,osCallArg0
        jsr     ACIA_putZ_osCallArg0
        sec
        rts

rtc_set_date_msg:
        .string "set date in form [hh:mm:ss:dd:mm:yy:cc:dw]",CR,LF,"(where cc is century, dw Sunday=00)",CR,LF
rtc_syntax_error:
        .string " at char - syntax error",CR,LF
rtc_err_msg:
        .string " i2c error message RTC",CR,LF
rtc_date_msg:
        .string "Internal clock reads: "

rtc_seps:
        .byte   ":: //? "
dow_table:
        .byte   "SunMonTueWedThuFriSat"
