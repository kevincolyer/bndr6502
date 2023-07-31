;===============================================
;       lcd screen - using via 6522
;===============================================

; PORT DEFINITIONS
VIA0_PORTB      = VIA0+0
VIA0_PORTA      = VIA0+1
VIA0_DDRB       = VIA0+2
VIA0_DDRA       = VIA0+3




E               = %10000000
RW              = %01000000
RS              = %00100000

via_init:
lcd_init:
        ifdef   symon           ; symon does not emulate lcd
        rts
        endif
        ifdef   nolcd           ; no lcd
        rts
        endif

        lda     #%11111111      ; Set all pins on port B to output
        sta     VIA0_DDRB
        lda     #%11100000      ; Set top 3 pins on port A to output
        sta     VIA0_DDRA

        lda     #%00111000      ; Set 8-bit mode; 2-line display; 5x8 font
        jsr     lcd_instruction
        lda     #%00001110      ; Display on; cursor on; blin
        ;lda #%00001111 ; Display on; cursor on; blink ON
        jsr     lcd_instruction
        lda     #%00000110      ; Increment and shift cursor; don't shift display
        jsr     lcd_instruction
                                ;  fall through
lcd_clear:
        lda     #$00000001      ; Clear display
        jmp     lcd_instruction

lcd_home:
        lda     #02             ; home and reset shift
        jmp     lcd_instruction

lcd_goto:
        ora     #$80            ; flag for set datadistplay index set or'd with desired index
        jmp     lcd_instruction

lcd_custom_char_write_mode:
        clc
        ;there are 8 chars avail. The cg data is index by byte, so x8 to find start point for CG for one char
        and     #$0f            ; write to character data - clear top bits (bit 4 don't matter! but as cg loops can do $08 instead of $00 )
        ror
        ror
        ror
        ora     #$40            ; set character graphics data index
        jmp     lcd_instruction

lcd_wait:
        pha
        lda     #%00000000      ; Port B is input
        sta     VIA0_DDRB
.lcdbusy:
        lda     #RW
        sta     VIA0_PORTA
        lda     #(RW|E)
        sta     VIA0_PORTA
        lda     VIA0_PORTB
        and     #%10000000
        bne     .lcdbusy

        lda     #RW
        sta     VIA0_PORTA
        lda     #%11111111      ; Port B is output
        sta     VIA0_DDRB
        pla
        rts

lcd_instruction:
        ifdef   symon           ; symon does not emulate lcd
        rts
        endif
        ifdef   nolcd           ; no lcd
        rts
        endif

        jsr     lcd_wait
        sta     VIA0_PORTB
        lda     #0              ; Clear RS/RW/E bits
        sta     VIA0_PORTA
        lda     #E              ; Set E bit to send instruction
        sta     VIA0_PORTA
        lda     #0              ; Clear RS/RW/E bits
        sta     VIA0_PORTA
        rts

lcd_print_char:
        ifdef   symon           ; symon does not emulate lcd
        rts
        endif
        ifdef   nolcd           ; no lcd
        rts
        endif

        jsr     lcd_wait
        pha
        sta     VIA0_PORTB
        lda     #RS             ; Set RS; Clear RW/E bits
        sta     VIA0_PORTA
        lda     #(RS|E)         ; Set E bit to send instruction
        sta     VIA0_PORTA
        lda     #RS             ; Clear E bits
        sta     VIA0_PORTA
        pla                     ; restore accumulator
        rts

; output a zero terminated buffer indexed from R0
lcd_print_buffz_r0:
        phy
        ldy     #0
.loop
        lda     (R0),y
        beq     .done
        jsr     lcd_print_char
        iny
        bne     .loop
.done
        ply
        rts

lcd_printwelcome:
        lda     #<lcdmsg
        sta     R0
        lda     #>lcdmsg
        sta     R0+1
        jmp     lcd_print_buffz_r0

lcdmsg:
        .byte   "Booting... ",0
