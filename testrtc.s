        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"

        .org    userStart       ; expected org
        ; userZp - origin of user zero page
        ; userLowMem - origin of user low mem space ~$600 to userStart

main:
        ; load monitor command to monitor
        ;         macro_store_symbol2word rtc_vec_cmd,osCallArg0
        ;         macro_oscall oscMonitorAddCmd
        macro_store_symbol2word rtc_date_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word rtc_zero_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd
        ;         macro_store_symbol2word rtc_alarm_cmd,osCallArg0
        ;         macro_oscall oscMonitorAddCmd
        macro_store_symbol2word rtc_wait_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word rtc_uptime_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd

        ; back to monitor
        os_monitor_return


;==============================================
rtc_date_cmd:
        .word   rtc_date_func_cmd
        .word   rtc_date_func
        .word   rtc_date_func_help

rtc_date_func_cmd:
        .byte   "rdate",0
rtc_date_func_help:
        .byte   "rdate-date rtc",CR,LF,0

rtc_date_func:
        jsr     rtc_date_func_rts
        os_monitor_return

rtc_date_func_rts:
        macro_store_symbol2word rtc_date_msg,osCallArg0
        macro_oscall oscPutZArg0

        lda     os_rtc_HOURS
        jsr     k_bin_to_bcd
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC

        lda     os_rtc_MINUTES
        jsr     k_bin_to_bcd
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC

        lda     os_rtc_SECONDS
        jsr     k_bin_to_bcd
        macro_oscall oscPutHexByte
        lda     #SPACE
        macro_oscall oscPutC

        lda     os_rtc_DAY
        jsr     k_bin_to_bcd
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC

        lda     os_rtc_MONTH
        jsr     k_bin_to_bcd
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC

        lda     os_rtc_YEAR
        jsr     k_bin_to_bcd
        macro_oscall oscPutHexByte

        macro_oscall oscPutCrLf
        rts

rtc_date_msg:
        .byte   "hh:mm:ss dd:mm:yy",CR,LF,0
k_bin_to_bcd:
        phy
        clc
        ldy     #8              ; 8 times through
        sta     osR0            ; bin to convert
        stz     osR0+1          ; bcd output init
.k_bin_to_bcdloop:
        asl     osR0            ; shift msb to carry
        sed
        lda     osR0+1          ; bcd
        adc     osR0+1          ; mult bcd by 2 adding carry
        sta     osR0+1
        cld
        dey
        bne     .k_bin_to_bcdloop
        ply                     ; done
        rts
        ;==============================================
rtc_zero_cmd:
        .word   rtc_zero_func_cmd
        .word   rtc_zero_func
        .word   rtc_zero_func_help
rtc_zero_func_cmd:
        .byte   "rzero",0
rtc_zero_func_help:
        .byte   "rzero-zero rtc",CR,LF,0

rtc_zero_func:
        stz     os_rtc_countdown+1
        stz     os_rtc_countdown
        stz     os_rtc_cs_32
        stz     os_rtc_cs_32+1
        stz     os_rtc_cs_32+2
        stz     os_rtc_cs_32+3

        macro_store_symbol2word rtc_zero_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

rtc_zero_msg:
        .byte   "Zero'ed counters",CR,LF,0

;=============================================

; rtc_alarm_cmd:
;         .byte   "ralarm",0
;         .word   rtc_alarm_func
;         .byte   "ralarm    - alarm rtc",CR,LF,0
;
; rtc_alarm_func:
;         macro_store_symbol2word rtc_alarm_msg,osCallArg0
;         macro_oscall oscPutZArg0
;
;         os_monitor_return
;
; rtc_alarm_msg:
;         .byte   "Function works well",CR,LF,0
;
; rtc_alarm_rang_msg:
;         .byte   "The alarm went off!",CR,LF,0

;-------------------------------------------

rtc_wait_cmd:
        .word   rtc_wait_func_cmd
        .word   rtc_wait_func
        .word   rtc_wait_func_help
rtc_wait_func_cmd:
        .byte   "rwait",0
rtc_wait_func_help:
        .byte   "rwait-wait for 1.5 seconds",CR,LF,0

rtc_wait_func:
        stz     os_rtc_countdown+1
        macro_store_symbol2word rtc_wait_msg,osCallArg0
        macro_oscall oscPutZArg0
.loop:
        lda     #100            ;one second
        sta     os_rtc_countdown
        jsr     rtc_date_func_rts; print time
.waitloop:
        macro_oscall oscGetC    ; get out
        bcs     .quit

        lda     os_rtc_countdown
        bne     .waitloop
        beq     .loop           ; user has to press a key to quit...

.quit:
        macro_store_symbol2word rtc_waited_msg,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return

rtc_waited_msg:
        .byte   "You waited...",CR,LF,0
rtc_wait_msg:
        .byte   "You wait...",CR,LF,0


;----------------------------------


rtc_uptime_cmd:
        .word   rtc_uptime_func_cmd
        .word   rtc_uptime_func
        .word   rtc_uptime_func_help
rtc_uptime_func_cmd:
        .byte   "ruptime",0
rtc_uptime_func_help:
        .byte   "ruptime-uptime rtc",CR,LF,0

rtc_uptime_func:
        lda     os_rtc_cs_32+3
        macro_oscall oscPutHexByte
        lda     os_rtc_cs_32+2
        macro_oscall oscPutHexByte
        lda     os_rtc_cs_32+1
        macro_oscall oscPutHexByte
        lda     os_rtc_cs_32
        macro_oscall oscPutHexByte

        macro_store_symbol2word rtc_uptime_msg,osCallArg0
        macro_oscall oscPutZArg0


        os_monitor_return

rtc_uptime_msg:
        .byte   " uptime ",CR,LF,0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; from http://6502.org/tutorials/interrupts.html#2.2

VIA0T1CL=VIA0+4
VIA0T1CH=VIA0+5
VIA0ACR=VIA0+11
VIA0IER=VIA0+14
; Init VIA timers and IRQ for software real-time clock operation.
; This is normally only called in the boot-up routine.  You may
; also want to reset time & date numbers if they don't make sense
; Set T1 to time out every 10ms @ CLOCK for 5Mz this is  $C34E is 49,998 decimal.
; T1 period = n+2 / φ2 freq
k_rtc_setup:
;time out for our clock
        ldx     #<os_rtc_cs_32  ; this code assumes the rtc zp addresses are in a contigous group!
.clearloop:
        stz     $00,x
        inx
        cpx     #<os_rtc_YEAR+1
        bne     .clearloop


        lda     #<TIMER1TIMEOUT ; see constants
        sta     VIA0T1CL        ;
        lda     #>TIMER1TIMEOUT
        sta     VIA0T1CH

        lda     #%01000000      ; T1 continous interrups
        sta     VIA0ACR         ; Enable VIA1 to generate an interrupt every time T1 times out.

k_rtc_on:
        lda     #%11000000      ; Enable  T1 time-out interrupt.
        sta     VIA0IER
        rts

k_rtc_off:
        lda     #%01000000      ; Disable T1 time-out interrupt.
        sta     VIA0IER
        rts
        ;------------------

; os_rtc_cs_32
;         dfs     4               ; Reserve 4 bytes of RAM variable space for a 32-bit centisecond counter.
;                                 ; This record rolls over about every 471 days.  It is to ease calculation
;                                 ; of times and alarms that could cross irrelevant calendar boundaries.
;                                 ; Byte order is low byte first, high byte last.
;
; os_rtc_CENTISEC
;         dfs     1               ; Now for the time-of-day (TOD) variables.
; os_rtc_SECONDS
;         dfs     1               ; Reserve one byte of RAM variable space for each of these numbers.
; os_rtc_MINUTES
;         dfs     1               ; At power-up, it's likely these numbers will make an invalid date
; os_rtc_HOURS
;         dfs     1               ; not just an incorrect date.  You might want to initialize them to
; os_rtc_DAY
;         dfs     1               ; a date that at least makes sense, like midnight 1/1/04.
; os_rtc_MONTH
;         dfs     1
; os_rtc_YEAR
;         dfs     1


MO_DAYS_TBL:                    ; Number of days at which each month needs to roll over to the next month:
        .byte   32,  29,  32,  31,  32,  31,  32,  32,  31,  32,  31,  32
                                ; Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec
        ;                                (Feb will get special treatment.)

; irq:
;         ; IRQ vector points here.  Usually only a few instructions
;         jmp (osSoftIrqVector)   ; this points to...
irq_test:                       ; ... this! (unless redirected)
        ;INCR10ms:
        pha                     ; get executed.  Save A since we'll use it below.
        ; we don't need to clear decimal as we are not using add instructions.
        lda     VIA0T1CL        ; Loading VIA0T1CL clears and resets timer VIA1 interrupt
                                ; timer is automatically reloaded...
        bra     .clock
        ; countdown timer
        lda     os_rtc_countdown; is countdown >0
        beq     .clock          ; 0 = no longer running

        ; countdown running and >1
        dec     os_rtc_countdown; decrement
        bne     .clock          ; is zero?
        lda     os_rtc_countdown+1; yes, is high byte zero?
        beq     .clock          ; yes, so done
        dec     os_rtc_countdown+1; no, so decrement..
        dec     os_rtc_countdown; and set lo byte to continue countdown

.clock:
        ; uptime and clock
        inc     os_rtc_cs_32    ; Increment the 4-byte variable cs_32.
        bne     .inc_TOD        ; If low byte didn't roll over, skip the rest.
        inc     os_rtc_cs_32+1  ; Else increment the next byte.
        bne     .inc_TOD        ; If that one didn't roll over, skip the rest.
        inc     os_rtc_cs_32+2  ; Etc..
        bne     .inc_TOD        ; (More than 99.6% of cases will skip out after
        inc     os_rtc_cs_32+3  ;  the first test.)

        ; You could end it here if you don't need TOD and calendar.

.inc_TOD:
        inc     os_rtc_CENTISEC ; Increment the hundredths of seconds in the 24-hour
        lda     os_rtc_CENTISEC ;                            clock/calendar section.
        cmp     #100            ; Compare cs to 100 (decimal, not hex).
        bmi     .end_int        ; If not there yet, skip the rest of this
        stz     os_rtc_CENTISEC ; Otherwise zero it,
        ; and go on to
        inc     os_rtc_SECONDS  ; increment the seconds.
        lda     os_rtc_SECONDS
        cmp     #60             ; See if seconds carries to another minute.
        bmi     .end_int        ; If not there yet, skip the rest of this.
        stz     os_rtc_SECONDS  ; Otherwise zero it,
        ; and go on to
        inc     os_rtc_MINUTES  ; increment the minutes.
        lda     os_rtc_MINUTES
        cmp     #60             ; See if minutes carries to another hour.
        bmi     .end_int        ; If not there yet, skip the rest of this.
        stz     os_rtc_MINUTES  ; Otherwise zero it,
        ; and go on to
        inc     os_rtc_HOURS    ; increment the hours.
        lda     os_rtc_HOURS
        cmp     #24             ; See if hours carries to another day.
        bmi     .end_int        ; If not there yet, skip the rest of this.
        stz     os_rtc_HOURS    ; Otherwise zero it,
        ; and go on to
        inc     os_rtc_DAY      ; increment the day.

        lda     os_rtc_MONTH    ; Now the irregular part.
        cmp     #2              ; Is it supposedly in February?
        bne     .notfeb         ; Branch if not.

        lda     os_rtc_YEAR     ; For Feb, we have to see what year it is.
        and     #%11111100      ; See if it's leap year by seeing
        cmp     os_rtc_YEAR     ; if it's a multiple of 4.
        bne     .notfeb         ; Branch if it's not;  ie, it's a 28-day Feb.

        lda     os_rtc_DAY      ; Leap year Feb should only go to 29 days.
        cmp     #30             ; Did Feb just get to 30?
        beq     .new_mo         ; If so, go increment month and re-init day to 1.
        pla                     ; Otherwise restore the accumulator
        rti                     ; and return to the regular program.

.notfeb:
        phx                     ; Save X for this indexing operation.
        ldx     os_rtc_MONTH    ; Get the month as an index into
        lda     MO_DAYS_TBL-1,x ; the table of days for each month to increment,
        plx                     ; and then restore X.
        cmp     os_rtc_DAY      ; See if we've reached that number of days
        bne     .end_int        ; If not, skip the rest of this.

.new_mo:
        lda     #1              ; Otherwise, it's a new month.  Put "1" in
        sta     os_rtc_DAY      ; the day of month again,
        inc     os_rtc_MONTH    ; and increment month.
        lda     os_rtc_MONTH
        cmp     #13             ; See if it went to the 13th moth.
        bne     .end_int        ; If not, go to end.
        lda     #1              ; Otherwise, reset the month to 1 (Jan),
        sta     os_rtc_MONTH

        inc     os_rtc_YEAR     ; and increment the year.

.end_int:
        pla
        rti

