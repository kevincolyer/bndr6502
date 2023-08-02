; sleep for A x 10ms
; calculates timing from systemclock constant
; calc=TODO

k_sleep_10_ms:
        phy
        phx
.outerloop:
        ldy     #$10
.midloop:
        ldx     #$ff
.innerloop:
        dex
        bne     .innerloop
        dey
        bne     .midloop
        dec
        bne     .outerloop
        plx
        ply
        rts

; converts a bye value less than 100 to bcd.
; divides by 2 orig, mults by 2 bcd and adds in the carry
; A holds number to convert
; preserves y,x
; uses osR0 as scratch space
; no overflow detection!
;-----------------------------
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

k_bcd_to_bin:
        pha                     ; stash for now
        and     #$f0            ; mask upper nybble
        lsr
        sta     osR0            ; store x8
        lsr
        lsr                     ; x2

        clc
        adc     osR0            ; add to stored x8 = x10
        sta     osR0
        pla
        and     #$0f
        adc     osR0            ; add lower nybble
        ;        sta osR0
        ; return converted byte
        rts


; sets random seed from A
k_seed_random:
        sta     osRandomSeed
;        eor     #<.magic
        sta     osRandomSeed+1
        rts

; returns a random byte from pseudo random generator
; from https://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
k_random:

.magic=$002d

        lda     osRandomSeed
        beq     .lowZero        ; $0000 and $8000 are special values to test for

        ; Do a normal shift
        asl     osRandomSeed
        lda     osRandomSeed+1
        rol
        bcc     .noEor

.doEor:
        ; high byte is in .A
        eor     #>.magic
        sta     osRandomSeed+1
        lda     osRandomSeed
        eor     #<.magic
        sta     osRandomSeed
        rts

.lowZero:
        lda     osRandomSeed+1
        beq     .doEor          ; High byte is also zero, so apply the EOR
        ; For speed, you could store 'magic' into 'seed' directly
        ; instead of running the EORs

        ; wasn't zero, check for $8000
        asl
        beq     .noEor          ; if $00 is left after the shift, then it was $80
        bcs     .doEor          ; else, do the EOR based on the carry bit as usual

.noEor:
        sta     osRandomSeed+1
        rts

; Limit in A of number to choose up to but not equal.
k_random_up_to:
        sta     osR0
        beq     .done           ; if a =0 quit!
.getanumber:
        jsr     k_random
        cmp     osR0            ; less than asked for?
        bcs     .getanumber
.done:
        rts



;-----------------------------------------------
; output a hex byte
;-----------------------------------------------
k_ACIA_putc_Hex_Byte:
        pha                     ; store for later
        clc
        lsr
        lsr
        lsr
        lsr                     ; shift higher to lower nybble
        tax
        lda     tableHexDigit,x
        jsr     k_ACIA_putc
        pla
        and     #$f             ; mask lower nybble
        tax
        lda     tableHexDigit,x
        jmp     k_ACIA_putc
decimals_table:
tableHexDigit:
        .byte   "0123456789abcdef",0

; compares A to see if hex. Returns value or $ff if not hex sets carry on error
k_is_decimal:
        clc
        phx
        ldx     #9
.is_dec_loop:
        cmp     decimals_table,x
        beq     .got_hex
        dex
        bpl     .is_dec_loop
        sec                     ; no so set carry
.got_hex:
        txa                     ; result in A ($ff not found)
        plx
        rts

; carry set on failure
; returns in A the value of hex nybble
; preserves x
k_is_hex_byte:
        phx
        ldx     #15
_k_is_hex_byteEntry2:
.ishex:
        cmp     tableHexDigit,x
        beq     .gotit
        dex
        bpl     .ishex
        sec
        bcs     .finish
.gotit:
        clc
        txa
.finish:
        plx
        rts

;-----------------------------------------------
; print a z terminated string located in x and y
;-----------------------------------------------
; puts a zero terminate string in R0 (x lo byte, y high byte) and callsk_ACIA_putc_z
k_ACIA_putz:
        stx     R0              ; lo byte
        sty     R0+1            ; high byte
        ; jmpk_ACIA_putc_z              ; fall through
        ; putc zero terminated string
        ; R0 holds buffer
        ; preserves y
k_ACIA_putc_z:
        phy
        ldy     #0
.loop:
        lda     (R0),y
        beq     .done
        jsr     k_ACIA_putc
        iny
        bne     .loop
.done:
        ply
        rts

;-----------------------------------------------
; print a z terminated string in osCallArg0
;-----------------------------------------------
k_ACIA_putz_osCallArg0:
        phy
        ldy     #0
.loop:
        lda     (osCallArg0),y
        beq     .done
        jsr     k_ACIA_putc
        iny
        bne     .loop
.done:
        ply
        rts

;-----------------------------------------------
; put a crlf
;-----------------------------------------------
k_ACIA_putc_crlf:
        lda     #CR
        jsr     k_ACIA_putc
        lda     #LF
        jmp     k_ACIA_putc

;-----------------------------------------------
;
;-----------------------------------------------
k_clear_os_output_buffer:
        stz     osOutputBufferLen
        stz     osOutputBuffer
        rts

;-----------------------------------------------
;
;-----------------------------------------------
k_clear_os_input_buf:
        stz     osInputBufferLen
        stz     osInputBuffer
        rts

;-----------------------------------------------
;
;-----------------------------------------------
k_ACIA_print_os_output_buf:
        phx
        phy
        ldx     #<osOutputBuffer
        ldy     #>osOutputBuffer
        jsr     k_ACIA_putz
        stz     osOutputBuffer
        stz     osOutputBufferLen
        ply
        plx
        rts

;-----------------------------------------------
;
;-----------------------------------------------
; preserves X Y
k_putc_os_output_buf:
        phx
        ldx     osOutputBufferLen
        cpx     #$FF            ; is buffer full?
        bne     .continue
        plx
        sec
        rts                     ; buffer is full signal error
.continue
        sta     osOutputBuffer,x
        inx
        stz     osOutputBuffer,x
        stx     osOutputBufferLen
        clc
        plx
        rts

;-----------------------------------------------
; zero terminated string pointed by A, X compared with buffer.
;-----------------------------------------------
; Preserves Y
; returns carry set if match
k_string_cmp_to_os_output_buf:
        phy
        sta     R0
        stx     R0+1
        ldy     #$0
        ldx     #$0
        clc
.loop
        lda     (R0),y
        beq     .eois           ; 0 = end of input string
        sta     R1
        lda     osOutputBuffer,x
        beq     .fail           ; 0 = end of output string
        eor     R1              ; xor with input string
        bne     .fail           ; if not 0 then not a match
        iny
        inx
        bne     .loop           ; branch if not 0
.eois
        cpy     osOutputBufferLen
        beq     .exactmatch     ; exactmatch - otherwise a prefix
        bne     .fail           ; would be a prefix case
.exactmatch
        sec
.fail
        ply
        rts

;-----------------------------------------------
; provides a line edit command with backspace to rub out.
;-----------------------------------------------
; Inputbuffer is 256 bytes but Arg0 set's max length (e.g. screen width)

k_line_editor:
        jsr     k_clear_os_input_buf
; get a char
.getachar:
        jsr     k_ACIA_getc
        bcc     .getachar
; if backspace try rubout
        cmp     #DEL
        beq     .tryRubOut
        cmp     #BS
        beq     .tryRubOut
        cmp     #CR
        beq     .return
;         cmp     #LF     ;debug
;         beq     .gotalf     ;debug
; otherwise add to buffer and echo
        jsr     k_ACIA_putc
        ldx     osInputBufferLen
        sta     osInputBuffer,x
        inx
        stz     osInputBuffer,x
        stx     osInputBufferLen
        cpx     osCallArg0      ; is the buffer going to overflow?
        bpl     .maxLength
        bra     .getachar
        ;
        ; .gotalf:     ;debug
        ;         jsr k_ACIA_putc_Hex_Byte     ;debug
        ;         bra .getachar     ;debug
        ; if cr return
.return:
        ;         jsr k_ACIA_putc_Hex_Byte     ;debug
        stz     osCallArg0+1    ; mark as ok return
        ;swallow any lf following
        ; .returnloop:
        ;         jsr k_ACIA_getc
        ;         bcc .returnloop
        ;         jsr k_ACIA_putc_Hex_Byte
        bra     .preparereturn
        ; if at max length return
.maxLength:
        stx     osCallArg0+1
.preparereturn:
        ldx     osInputBufferLen
        stz     osInputBuffer,x
        lda     #CR
        jsr     k_ACIA_putc
        lda     #LF
        jsr     k_ACIA_putc
        ; check we need to signal error
        lda     osCallArg0+1
        beq     .end
        macro_putz .msg_buffer_overflow
.end:
        rts

.msg_buffer_overflow:
        .byte   "input buffer overflow",CR,LF,0
.tryRubOut:
; if not at len 0                               ; NOTE - need to start with an indent so we don't rub out prompt
        lda     osInputBufferLen
        beq     .getachar       ; at zero so nothing to rub out
        tax
        dec     osInputBufferLen
        stz     osInputBuffer,x
        macro_putz .bs_space_bs
        jmp     .getachar
        ; echo backspace space backspace
.bs_space_bs:
        ifdef   symon
        .byte   DEL,SPACE,DEL,0
        else
        .byte   BS,SPACE,BS,0
        endif

;-----------------------------------------------
; 16bit decimal osArgCall0 to text
;-----------------------------------------------
; osArgCall1 has pad character of 0 or 'whatever'
; result in consecutive bytes osArgCall0,osArgCall1,osArgCall2 z terminated
; modified from https://beebwiki.mdfs.net/Number_output_in_6502_machine_code
k_string_word_to_decimal:
        ; On entry,
        ;           osCallArg0 = vector of buffer to print to
        ;           osCallArg1 = number to print
        ;           osCallArg2=0 or pad character (eg '0' or ' ')
        ; On entry at PrDec16Lp1,
        ;           Y=(number of digits)*2-2, eg 8 for 5 digits
        ; -----------------------------------------------------------------

        stz     R0              ; index to output string

.PrDec16:
        ldy     #8              ; Offset to powers of ten (points to 10000)
.PrDec16Lp1:
        ldx     #$FF            ; counter of how many times we subtract
        sec                     ; Start with digit=-1
.PrDec16Lp2:
        ; Subtract current power of 10
        lda     osCallArg1
        sbc     .PrDec16Tens,Y
        sta     osCallArg1
        lda     osCallArg1+1
        sbc     .PrDec16Tens+1,Y
        sta     osCallArg1+1
        inx
        bcs     .PrDec16Lp2     ; Loop until <0
        ; Add current power of ten back in
        lda     osCallArg1
        adc     .PrDec16Tens+0,Y
        sta     osCallArg1
        lda     osCallArg1+1
        adc     .PrDec16Tens+1,Y
        sta     osCallArg1+1
        txa                     ; how many subtractions
        bne     .PrDec16Digit   ; Not zero, print it
        lda     osCallArg2      ; pad<>0, so use it as pad char
        bne     .PrDec16Print
        beq     .PrDec16Next
.PrDec16Digit:
        ldx     #"0"
        stx     osCallArg2      ; No more zero padding
        ora     #"0"            ; Print this digit
.PrDec16Print:
        ; instead of JSR OSWRCH
        phy                     ; save y
        ldy     R0
        sta     (osCallArg0),y
        iny
        sty     R0
        ply                     ; restore y
.PrDec16Next:
        dey
        dey                     ; descend through powers of 2 table
        bpl     .PrDec16Lp1     ; Loop for next digit
                                ; none left so done!
        ; finish with z temination.
        ldy     R0
        lda     #0
        sta     (osCallArg0),y  ; teminating 0
        rts

.PrDec16Tens:
        .word   1
        .word   10
        .word   100
        .word   1000
        .word   10000

;-----------------------------------------------
; copy z terminated string osCallArg0 to osCallArg1
;-----------------------------------------------
; NOTE 256 bytes MAX
k_string_z_copy:
        ldy     #0
.loop:
        lda     (osCallArg0),y
        sta     (osCallArg1),y
        beq     .end            ; if 0 end
        iny
        beq     .end            ; if wrapped around to 0 end
        bne     .loop
.end:
        rts
