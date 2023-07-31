;===============================================
;       lcd screen - using via 6522
;===============================================
        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"

        .org    userStart       ; expected org
        ; userZp - origin of user zero page
        ; userLowMem - origin of user low mem space ~$600 to userStart

main:
        ; load monitor command to monitor

        macro_store_symbol2word testcmd2,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd3,osCallArg0
        macro_oscall oscMonitorAddCmd

        jsr     via_init

        ; back to monitor
        os_monitor_return


testcmd2:
        .word   test_lcd_panel_cmd_cmd
        .word   test_lcd_panel_cmd
        .word   test_lcd_panel_cmd_help

test_lcd_panel_cmd_cmd:
        .byte   "2",0
test_lcd_panel_cmd_help:
        .byte   "2    - test 4bit control lcd panel",CR,LF,0

testcmd3:
        .word   test_lcd_panel_cmd3_cmd
        .word   test_lcd_panel_cmd3
        .word   test_lcd_panel_cmd3_help

test_lcd_panel_cmd3_cmd:
        .byte   "3",0
test_lcd_panel_cmd3_help:
        .byte   "3    - test prniting to lcd panel",CR,LF,0


test_lcd_panel0:
        .string "Starting lcd panel init",CR,LF
test_lcd_panel1:
        .string "lcd panel init",CR,LF
test_lcd_panel2:
        .string "lcd panel print",CR,LF
test_lcd_panel3:
        .string "enter a test message to print to lcd",CR,LF
test_lcd_panel4:
        .string "printing to lcd...",CR,LF
; ----------------------------------------------------------------


test_lcd_panel_cmd:
        ; pre init message
        macro_store_symbol2word test_lcd_panel0,osCallArg0
        macro_oscall oscPutZArg0

        jsr     lcd_clear

        ; post init message
        macro_store_symbol2word test_lcd_panel1,osCallArg0
        macro_oscall oscPutZArg0

        jsr     lcd_printwelcome

        ; post print message
        macro_store_symbol2word test_lcd_panel2,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

test_lcd_panel_cmd3:
        macro_store_symbol2word test_lcd_panel0,osCallArg0
        macro_oscall oscPutZArg0


        ;ask for a message to print
        macro_store_symbol2word test_lcd_panel3,osCallArg0
        macro_oscall oscPutZArg0

        lda     #80
        sta     osCallArg0
        macro_oscall oscLineEditInput

        ; print it
        macro_store_symbol2word test_lcd_panel4,osCallArg0
        macro_oscall oscPutZArg0

        jsr     lcd_clear       ; takes too long?


        macro_store_symbol2word osInputBuffer,osR0


        jsr     lcd_print_buffz_r0

        os_monitor_return
;-------------------------------------------------------------------
; PORT DEFINITIONS
VIA0_PORTB      = VIA0
VIA0_PORTA      = VIA0+1
VIA0_DDRB       = VIA0+2
VIA0_DDRA       = VIA0+3

; WIRING GUIDE!!!!
;     port B pins: 76543210  also wire bit 3 to bit 7 (for busy reading)
        ;  --------
E               = %01000000
RW              = %00100000
RS              = %00010000

DATAPINS        = %00001111     ; to pins 7-4 of LCD (leave 0-3 lcd pins floating)
nybblestore     = userZp


via_init:

        ifdef   symon           ; symon does not emulate lcd
        rts
        endif

        lda     #%01111111      ; Set all pins on port B to output
                                ; except pin 7 - use that for detecting ready state
        sta     VIA0_DDRB
        lda     #2
        jsr     LCDosSleep10ms
        ; function set - 4bit mode (single write first)
        lda     #%0011          ; Function set
        jsr     lcd_instruction_nybble
        lda     #%0010          ; set 4 bit mode
        jsr     lcd_instruction_nybble
        ; function set (two part writes from now on)
        lda     #%00101000      ; Set 4-bit mode; 2-line display; 5x8 font
        jsr     lcd_instruction
        ; display control
        lda     #%00001111      ; Display on; cursor on; blink ON
        lda     #%00001110      ; Display on; cursor on; blink OFF
        jsr     lcd_instruction
        ; entry mode
        lda     #%00000110      ; Increment and shift cursor
                                ; don't shift display
        jsr     lcd_instruction
        ;  fall through to clear
lcd_clear:
        lda     #$00000001      ; Clear display
        jsr     lcd_instruction
        lda     #2
        jmp     LCDosSleep10ms

lcd_home:
        lda     #$00000010      ; home and reset shift
        jsr     lcd_instruction
        lda     #2
        jmp     LCDosSleep10ms

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

lcd_wait:                       ; preserves A
        pha
.lcdbusy:
        lda     #RW
        sta     VIA0_PORTB
        lda     #(RW|E)
        sta     VIA0_PORTB
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        ;  check for ready signal
        bit     VIA0_PORTB
        ;         and     #%10000000
        ;         bne     .lcdbusy
        bmi     .lcdbusy

        lda     #RW
        sta     VIA0_PORTB
        pla
        rts

; sends a byte as 2 nybbles
lcd_instruction:
        ifdef   symon           ; symon does not emulate lcd
        rts
        endif
lcd_instruction_2_part:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     lcd_instruction_nybble
        pla
        and     #$f
        jmp     lcd_instruction_nybble



lcd_instruction_nybble:
        and     #DATAPINS
        sta     nybblestore

        jsr     lcd_wait
        ;and     #$0f              ; Clear RS/RW/E bits (low for writing)
        sta     VIA0_PORTB
        lda     nybblestore
        ora     #E              ; Set E bit to send instruction
        sta     VIA0_PORTB
        lda     nybblestore
        ;and     #$0f              ; Clear RS/RW/E bits
        sta     VIA0_PORTB
        rts

; prints a byte as 2 nybbles
lcd_print_char:
        ifdef   symon           ; symon does not emulate lcd
        rts
        endif
lcd_print_char_2_part:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     lcd_print_nybble
        pla
        and     #$f
        jmp     lcd_print_nybble


lcd_print_nybble:
        pha
        and     #DATAPINS
        sta     nybblestore

        jsr     lcd_wait
        ;sta     VIA0_PORTB
        ora     #RS             ; Set RS; Clear RW/E bits
        sta     VIA0_PORTB
        lda     nybblestore
        ora     #(RS|E)         ; Set E bit to send data
        sta     VIA0_PORTB
        lda     nybblestore
        ora     #RS             ; Clear E bits
        sta     VIA0_PORTB
        pla                     ; restore accumulator
        rts

; output a zero terminated buffer indexed from osR0
lcd_print_buffz_r0:
        phy
        ldy     #0
.loop
        lda     (osR0),y
        beq     .done
        jsr     lcd_print_char
        iny
        bne     .loop
.done
        ply
        rts

lcd_printwelcome:
        lda     #<lcdmsg
        sta     osR0
        lda     #>lcdmsg
        sta     osR0+1
        jmp     lcd_print_buffz_r0

lcdmsg:
        .byte   "Booting...",0


; note this is code from a system call - should become one in next rev!
LCDosSleep10ms:
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
