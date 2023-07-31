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
        macro_store_symbol2word testcmd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word testcmd2,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word testcmd3,osCallArg0
        macro_oscall oscMonitorAddCmd

        stz     toggle          ; init variables
        jsr     via_init
        jsr     toggle_led      ; switch on

        ; back to monitor
        os_monitor_return
testcmd:
        .word   miscfunction_cmd
        .word   miscfunction
        .word   miscfunction_help
miscfunction_cmd:
        .byte   "1",0
miscfunction_help:
        .byte   "1    - blink led",CR,LF,0

testcmd2:
        .word   test_lcd_panel_cmd_cmd
        .word   test_lcd_panel_cmd
        .word   test_lcd_panel_cmd_help
test_lcd_panel_cmd_cmd:
        .byte   "2",0
test_lcd_panel_cmd_help:
        .byte   "2    - test 8bit control lcd panel",CR,LF,0

testcmd3:
        .word   test_lcd_panel_cmd3_cmd
        .word   test_lcd_panel_cmd3
        .word   test_lcd_panel_cmd3_help
test_lcd_panel_cmd3_cmd:
        .byte   "3",0
test_lcd_panel_cmd3_help:
        .byte   "3    - test priting to lcd panel",CR,LF,0

miscfunction:
        jsr     service_via_and_toggle
        macro_store_symbol2word testcmd_msg,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return
testcmd_msg:
        .byte   "1 function triggered "
viareport:
        .string "0",CR,LF

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
; meat and bone routine
service_via_and_toggle:
        jsr     toggle_led
        lda     toggle          ;
        beq     .off
        lda     #'1'
        bra     .store
.off:
        lda     #'0'
.store:
        sta     viareport
        rts

test_lcd_panel_cmd:
        ; pre init message
        macro_store_symbol2word test_lcd_panel0,osCallArg0
        macro_oscall oscPutZArg0

        jsr     via_init

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
        jsr     via_init

        ;ask for a message to print

        macro_store_symbol2word test_lcd_panel3,osCallArg0
        macro_oscall oscPutZArg0

        lda     #80
        sta     osCallArg0
        macro_oscall oscLineEditInput

        ;print it
        macro_store_symbol2word test_lcd_panel4,osCallArg0
        macro_oscall oscPutZArg0

        jsr     lcd_clear
        macro_store_symbol2word osInputBuffer,osR0
        jsr     lcd_print_buffz_r0

        os_monitor_return
;-------------------------------------------------------------------
; PORT DEFINITIONS
VIA0_PORTB      = VIA0
VIA0_PORTA      = VIA0+1
VIA0_DDRB       = VIA0+2
VIA0_DDRA       = VIA0+3


LED             = %00010000

E               = %10000000
RW              = %01000000
RS              = %00100000

toggle          = userZp        ;


via_init:

        ifdef   symon           ; symon does not emulate lcd
        rts
        endif

        lda     #%11111111      ; Set all pins on port B to output
        sta     VIA0_DDRB
        lda     #%11110000      ; Set top 4 pins on port A to output
        sta     VIA0_DDRA

        lda     #%00111000      ; Set 8-bit mode; 2-line display; 5x8 font
        jsr     lcd_instruction
        lda     #%00001110      ; Display on; cursor on; blink off
        ;lda #%00001111 ; Display on; cursor on; blink ON
        jsr     lcd_instruction
        lda     #%00000110      ; Increment and shift cursor; don't shift display
        jsr     lcd_instruction
        ;  fall through
lcd_clear:
        lda     #$00000001      ; Clear display
        jmp     lcd_instruction


toggle_led:
        lda     #%11110000      ; Set top 4 pins on port A to output
        sta     VIA0_DDRA


        lda     toggle
        eor     #$ff
        sta     toggle
        ;and #LED
        sta     VIA0_PORTA
        rts


















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
        .byte   "Booting... ",0
