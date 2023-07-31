; code from https://raw.githubusercontent.com/dourish/secnd/master/iorom.a65
;;;
;;; Paul Dourish, July 2021
;;;


;;; VIA registers
;;;
VIA0_PORTB=VIA0
VIA0_DDRB=VIA0+2

SPI_PORT=VIA0_PORTB



; ;; Command/Data codes for SPI
; DATAWRITE=$00
; DATAREAD=$40
; CMDWRITE=$80
; CMDREAD=$c0



;;;
;;; Low-level SPI code
;;;
;;;

;;;
;;; Wiring details:
;;;   CLK is PB0, ie 1
;;;   MOSI is PB1, ie 2
;;;   CS is PB2, ie 4
;;;   MISO is PB7, which maps onto S flag on BIT (test with BPL and BMI)
;;; MISO, MOSI, and CS all have pull-up resisters, so they are high in
;;; the idle/unused state, except when pulled low by active circuitry.
;;;
;;; For the moment, this is the same setup as the SD card reader.
;;; Since I want to be able to set things up for keyboard input on
;;; on the same port, I'm likely to want to move some of the lines
;;; around later. However, for now, I wannt to use validated code.
;;;
;;; Device is SPI Mode 0. This means:
;;;   clock idles low
;;;   clock active high
;;;   data read on rising edge

SPI_CLK         = 1
SPI_MOSI        = 2
SPI_CS_0        = 4
SPI_CS_1        = 8
SPI_CS_2        = 16
SPI_CS_3        = 32
SPI_MISO        = 128



k_SPI_init:
        lda     #SPI_CLK|SPI_MOSI|SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3; As master I write clock, master out, cs 0 to 4
        sta     VIA0_DDRB
        lda     #SPI_MOSI|SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3
        sta     SPI_PORT        ; zero everything but mosi and slave lines
        rts

; preserves X,Y
; A holds number of cycles to pump SPI clk
k_SPI_Pump_CLK:
        phx
        tax
        lda     #SPI_CLK|SPI_MOSI|SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3;3; all CS high. (not selected)
        ; toggle the clock X times but with CS high on all
.preinitloop:
        eor     #SPI_CLK
        sta     SPI_PORT
        dex
        bne     .preinitloop
        plx
        rts

;;; Send a byte via SPI. This faster version of the original code
;;; unrolls the loop and relies on shifts rather than branches to
;;; determine the bit to send. This is written on the assumption
;;; that the CLK signal idles low.
;;;
; note this code depends on the SPI_CLK being on bit 0 so inc and dec instructions can flip it for the clock.
; x and y are used so y holds constant value to sending 1 and x holds constant value for sending a 0
; -> A byte to write
; -> Y slave device to select 0-3
k_SPI_Send_Byte:
        phx
        phy
        pha

; calculate the device number (mask so only 4 devices)
        tya
        and     #3
        tay
; setup pin of cs 0
        lda     #SPI_CS_0
; shift right one
        lsr
.loop:
        asl                     ; shift left one
        dey                     ; y times
        bpl     .loop
        ; right, device pin in correct position.
        ; set constants
        eor     #SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3; pulldown only slave I need
        tax                     ; X another constant -- clk 0, mosi 0, slave=0
        ora     #SPI_MOSI       ; set mosi to 1
        tay                     ; Y constant -- clk 0, mosi 1, slave =0
        ; setup complete
        pla                     ; restore byte to send
        ; ready to start!

        asl                     ; top bit of a into carry
        bcs     .bit7_1
        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit6

.bit7_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit6:
        asl
        bcs     .bit6_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit5

.bit6_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit5:
        asl
        bcs     .bit5_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit4

.bit5_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit4:
        asl
        bcs     .bit4_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit3

.bit4_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit3:
        asl
        bcs     .bit3_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit2

.bit3_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit2:
        asl
        bcs     .bit2_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit1

.bit2_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit1:
        asl
        bcs     .bit1_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .bit0

.bit1_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.bit0:
        asl
        bcs     .bit0_1

        stx     SPI_PORT        ; set ck 0, mosi 0
        inc     SPI_PORT        ; then clk 1
        bra     .sent

.bit0_1:
        sty     SPI_PORT        ; updates both ck and mosi
        inc     SPI_PORT        ; set clock

.sent:
        sty     SPI_PORT
;         tya
;         ora     #SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3
;         sta     SPI_PORT        ; leave clk low, MOSI high, slaves high
        ply
        plx
        rts



;;; read a byte via SPI from SPI_PORT, returned in accumulator.
;;; Assume the CLK idles low.
; Y - holds slave number to write to (0-3)

k_SPI_Recv_Byte:
        phy
; calculate the device number (mask so only 4 devices)
        tya
        and     #3
        tay
; setup pin of cs 0
        lda     #SPI_CS_0
; shift right one
        lsr
.loop:
        asl                     ; shift left one
        dey                     ; y times
        bpl     .loop
        ; right, device pin in correct position.
        ; set constants
        eor     #SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3; pulldown only slave I need
        ora     #SPI_MOSI
        tay                     ; Y constant -- clk 0, mosi 0, cs low for that line others high

; start!
        lda     #0
bit7:
        sty     SPI_PORT        ; clk low, mosi low
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit7_0

        sec
        rol
        bra     .bit6

.bit7_0:
        asl

.bit6:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit6_0

        sec
        rol
        bra     .bit5

.bit6_0:
        asl

.bit5:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit5_0

        sec
        rol
        bra     .bit4

.bit5_0:
        asl

.bit4:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit4_0

        sec
        rol
        bra     .bit3

.bit4_0:
        asl

.bit3:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit3_0

        sec
        rol
        bra     .bit2

.bit3_0:
        asl

.bit2:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit2_0

        sec
        rol
        bra     .bit1

.bit2_0:
        asl

.bit1:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit1_0

        sec
        rol
        bra     .bit0

.bit1_0:
        asl

.bit0:
        sty     SPI_PORT
        inc     SPI_PORT        ; sets clock but also reads data into SPI_MISO
        bpl     .bit0_0

        sec
        rol
        bra     .endread

.bit0_0:
        asl

.endread:
        ; result in A
        dec     SPI_PORT        ; leave clk low
        ;         ldy     #SPI_MOSI|SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3
        ;         sty     SPI_PORT

        ply
        rts

;---------------------------------------------
        .macro  macro_shift_and_send_and_receive,zp
        asl
        bcs     .bit_1_\@

.bit_0_\@:
        stx     SPI_PORT        ; set ck 0, mosi 0
        ;inc     SPI_PORT        ; then clk 1
        bra     .bit_read_\@

.bit_1_\@:
        sty     SPI_PORT        ; updates both ck and mosi

.bit_read_\@:
        inc     SPI_PORT        ; trigger clock pulse

        bit     SPI_PORT        ; read in what slave sent on clock pulse
        bpl     .bit_shift_\@   ; is it a 0 (+ve) or a 1 (-ve)

        inc     \zp             ; = 1
.bit_shift_\@:
        lsr     \zp             ; (?=0) and shift
.bit_next_\@:
        .endm


;

;---k_SPI_Write_Read_Byte ---------------------------------------------
; A -> byte to write
; A <- byte read
; Y <-> cs to use (0-3)
; zp uses R0
; Preserves X, (and Y)
k_SPI_Write_Read_Byte:
        phx
        phy
        pha

; calculate the device number (mask so only 4 devices)
        tya
        and     #3
        tay

        lda     #SPI_CS_0       ; start with pin of cs 0

        lsr                     ; shift right once
.loop:
        asl                     ; shift left once
        dey                     ; y times
        bpl     .loop
        ; device pin now in correct bit position.
        ; set constants
        eor     #SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3; invert to pulldown only slave device I need
        tax                     ; X another constant -- clk 0, mosi 0, slave low
        ora     #SPI_MOSI       ; set mosi to 1
        tay                     ; Y constant -- clk 0, mosi 1, slave low
        ; setup complete
        pla                     ; restore byte to send
        ; ready to start!
        stz     osCallArg0      ; TODO change this to an os value

        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0
        macro_shift_and_send_and_receive osCallArg0

.sent:
        tya
        ora     #SPI_CS_0|SPI_CS_1|SPI_CS_2|SPI_CS_3
        sta     SPI_PORT        ; leave clk low, MOSI high, slaves high
        ply
        plx
        lda     osCallArg0
        rts
