; quick test program to see if we can load and execute a binary program
        .include "os_memorymap.inc"



buffer          = userLowMem

; -------------------------------------------------
; main program initialise
; -------------------------------------------------

        .org    romStart
main:
        jsr     serial_acia_init
        jsr     serial_send_CLS
        jsr     lcd_init
        ; bender eyes - load custom chars to lcd
        lda     #6              ; next trans is to left facing; currently right
        sta     R2              ; benders eyes switching
        ; mkae this a sub - char index multply by 8
        ldx     #0
        txa
        jsr     lcd_custom_char_write_mode; start cg writing at index 0
.loop:
        lda     bender,x
        bmi     .reset_cg_mode  ;         found a high bit, so quit loop
        jsr     lcd_print_char
        inx
        bra     .loop

; reset lcd character graphics load by sending a data command
.reset_cg_mode
        lda     #$40
        jsr     lcd_goto


; print a welcome message on LCD
print_lcd_welcome:
        lda     #<lcd_welcome1
        sta     R0
        lda     #>lcd_welcome1
        sta     R0+1
        jsr     lcd_print_buffz_r0
        jsr     lcd_home
        lda     #<lcd_welcome0
        sta     R0
        lda     #>lcd_welcome0
        sta     R0+1
        jsr     lcd_print_buffz_r0
; all setup done.

;-----------------------------------------------------------------
; main program loop
; print a message
; accept input
; upper case it
; rinse and repeat
; ----------------------------------------------------------------

print_serial_prompt:
write:
        ldx     #0              ; top of loop
nextchar1:
        lda     .text,x
        beq     read            ; end of message
        jsr     serial_send_char
        inx
        bra     nextchar1
.text:
        byte    "(L)ist all devices on bus, (T)emprature prepare (R)ead device 1 and 2",CR,LF,0

; read stream of chars into a osInputBuffer, echoing and handling back delete
read:
        ldx     #0
        stz     osInputBuffer,x ; initialise buffer
.next_char:
        jsr     serial_get_char
        cmp     #DEL
        beq     .delete
        cmp     #CR             ; keep reading until get sent a linefeed (or CR?)
        beq     .finishread
        cmp     #CTRL_C         ; CTRL_C interception - just for practice
        bne     .cont
        jsr     serial_send_CRLF
        bra     write           ; leave early on CTRL_C
.cont:
        jsr     serial_send_char; ECHO
        sta     osInputBuffer,x
        cmp     #'e'
        bne     .cont2
        jsr     lcd_bendereyes
.cont2:
        inx
        bra     .next_char
        ; handle delete
.delete:
        cpx     #0
        beq     .next_char      ; if we are at line beginning do nothing
        dex
        jsr     serial_send_BS
        bra     .next_char

.finishread:
        stz     osInputBuffer,x
        jsr     serial_send_CRLF

; send osInputBuffer back to terminal one char at a time (converting as we go)
echo:
        ldx     #0
.loop:
        lda     osInputBuffer,x ;  reading chars sent
        beq     .done
.send:
        jsr     serial_send_char
        jsr     lcd_print_char
        inx
        bra     .loop
.done:
        jsr     serial_send_CRLF
        jmp     write

; flick benders eyes
lcd_bendereyes:
        pha
        lda     #$41
        jsr     lcd_goto
        lda     R2
        jsr     lcd_print_char
        inc
        jsr     lcd_print_char
        dec
        eor     #2
        sta     R2
        pla
        rts
;---------------------------------------------------
; Serial port routines - ACIA
;---------------------------------------------------

ACIA_DATA       = ACIA0
ACIA_STATUS     = ACIA0 + 1
ACIA_COMMAND    = ACIA0 + 2
ACIA_CONTROL    = ACIA0 + 3

; ASCII defines
LF              = $0A
CR              = $0D
ESC             = $1B
BS              = $08
SPACE           = $20
DEL             = $7F
ETX             = $03           ; = CTRL-C usually
CTRL_C          = ETX

serial_acia_init:
        lda     #%00001011      ;No parity, no echo, no interrupt
        sta     ACIA_COMMAND
        lda     #%00011111      ;1 stop bit, 8 data bits, 19200 baud
        sta     ACIA_CONTROL
        rts

; serial_send_char via serial port
serial_send_char:
        pha
.wait:
        lda     ACIA_STATUS
        and     #$10
        beq     .wait
        pla
        sta     ACIA_DATA
        rts

; serial_get_char from serial port
serial_get_char:
        lda     ACIA_STATUS
        and     #$08
        beq     serial_get_char
        lda     ACIA_DATA
        rts

; send backspace to erase a char
serial_send_BS:
        lda     #BS
        jsr     serial_send_char
        lda     #SPACE
        jsr     serial_send_char
        lda     #BS
        jmp     serial_send_char

; send cr lf combo
serial_send_CRLF:
        lda     #CR
        jsr     serial_send_char
        lda     #LF
        jmp     serial_send_char

;send a byte as two digit hex
serial_send_HEX:
        pha
        lsr
        lsr
        lsr
        lsr
        clc
        adc     #'0'
        cmp     #'9'+1
        bcc     .sendit
        adc     #6              ; plus carry=1
.sendit
        jsr     serial_send_char
        pla
        and     #$0f
        adc     #'0'
        cmp     #'9'+1
        bcc     .sendit2
        adc     #6              ; plus carry=1
.sendit2:
        jmp     serial_send_char

; send clear screen and home chars
serial_send_CLS:
        ldx     #0
.loop:
        lda     _cls,x
        beq     .end
        jsr     serial_send_char
        inx
        bra     .loop
.end:
        rts

; send Home
serial_send_HOME:
        ldx     #0
.loop1:
        lda     _home,x
        beq     .end
        jsr     serial_send_char
        inx
        bra     .loop1
.end:
        rts



_cls:
        .byte   ESC,"[H",ESC,"[J",0
_home:
        .byte   ESC,"[H",0


;-------------------------------------------------------
; LCD 1602 Drivers
;-------------------------------------------------------
; data for custom chars for 5x8 mode LCD1602
bender:
; BNDR15x16-0-0.png
        .byte   %00000, %00000, %00000, %00000, %00001, %00110, %01000, %01000
; BNDR15x16-1-0.png
        .byte   %11000, %01000, %01000, %11100, %00010, %00001, %00000, %00000
; BNDR15x16-2-0.png
        .byte   %00000, %00000, %00000, %00000, %00000, %10000, %01000, %00100
; BNDR15x16-0-1.png
        .byte   %10000, %10001, %10011, %10011, %10011, %10011, %10011, %10010
; BNDR15x16-1-1.png **
        .byte   %00000, %11111, %00000, %01110, %01100, %01000, %11111, %10101
; BNDR15x16-2-1.png **
        .byte   %00100, %11110, %00001, %11101, %11001, %10001, %11110, %01010

; left looking eyes
; BNDR15x16-1-1-L.png
        .byte   %00000, %11111, %00000, %01110, %00110, %00010, %11111, %10101
; BNDR15x16-2-1-L.png
        .byte   %00100, %11110, %00001, %11101, %01101, %00101, %11110, %01010
        ; FF marks end of data - the display only takes the lower 5 bits
        .byte   $FF


lcd_welcome0
        .byte   8,9,10,"BNDR6502",0
lcd_welcome1
        .byte   3,4,5,"is great!",0

VIA0_PORTB      = VIA0 + 0
VIA0_PORTA      = VIA0 + 1
VIA0_DDRB       = VIA0 + 2
VIA0_DDRA       = VIA0 + 3

E               = %10000000
RW              = %01000000
RS              = %00100000

lcd_init:

        lda     #%11111111      ; Set all pins on port B to output
        sta     VIA0_DDRB
        lda     #%11100000      ; Set top 3 pins on port A to output
        sta     VIA0_DDRA

        lda     #%00111000      ; Set 8-bit mode; 2-line display; 5x8 font
        jsr     lcd_instruction
        lda     #%00001110      ; Display on; cursor on; blink off
        ;lda #%00001111 ; Display on; cursor on; blink ON
        jsr     lcd_instruction
        lda     #%00000110      ; Increment and shift cursor; don't shift display
        jsr     lcd_instruction
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
        lda     #RW|E
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
        jsr     lcd_wait
        pha
        sta     VIA0_PORTB
        lda     #RS             ; Set RS; Clear RW/E bits
        sta     VIA0_PORTA
        lda     #RS|E           ; Set E bit to send instruction
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
; just for practice!
;      .align 8 ; makes little difference as xmodem protocal pads to 128 byte buffers
;      .align 12 ; align to 12 bits = 4k boundary here...
END_OF_PRG:
