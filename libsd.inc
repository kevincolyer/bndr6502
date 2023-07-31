; adapted from https://github.com/gfoot/sdcard6502/blob/master/src/libsd.s
; SD card interface module
; also refer to https://openlabpro.com/guide/interfacing-microcontrollers-with-sd-card/
;
; Requires zero-page variable storage: (defined in os_memorymap.inc)
;   zp_sd_address       - 2 bytes
;   zp_sd_currentsector - 4 bytes
;
; define  DEBUGSD if needed
;
; macro is needed to make the sd card respond. It needs pumping with cs hi and then low (or writing a byte) before each command
; samsung SD worked after this
; iflash microsd (2Gb) never worked.
; Why? Just would not read BPB - even though was set to $800 in MBR and was apparantly loaded - just never did. Wierd.

        .macro  pump_and_write,cycles
        lda     #\cycles
        jsr     k_SPI_Pump_CLK
        lda     #$ff
        jsr     sd_writebyte
        .endm
; TODO - for clean up there needs to be some redirection so that reading an SD card is not tied so deeply to the CS line
; hence need for below

SD_CS_INDEX=0

sd_init:

        ; Let the SD card boot up, by pumping the clock with SD CS disabled
        ; We need to apply around 80 clock pulses with CS and MOSI high.
        ; Normally MOSI doesn't matter when CS is high, but the card is
        ; not yet is SPI mode, and in this non-SPI state it does care.

        ; C set = Failure

        lda     #80
        jsr     k_SPI_Pump_CLK


.cmd0   ; GO_IDLE_STATE - resets card to idle state, and SPI mode
        lda     #<sd_cmd0_bytes
        sta     zp_sd_address
        lda     #>sd_cmd0_bytes
        sta     zp_sd_address+1

        jsr     sd_sendcommand

        ; Expect status response $01 (not initialized)
        cmp     #$01
        bne     .initfailed0

.cmd8   ; SEND_IF_COND - tell the card how we want it to operate (3.3V, etc)
        pump_and_write 8

        lda     #<sd_cmd8_bytes
        sta     zp_sd_address
        lda     #>sd_cmd8_bytes
        sta     zp_sd_address+1

        jsr     sd_sendcommand


        ; note TODO chech for $05 as a response
        ;
        ; Suppose the response of CMD8 resulted in 0x05, a few considerations have to be made regarding the initialization procedure. Version 1 cards may not support the ACMD41 command. And even if they do support the ACMD41 command, send the CMD55 command and check for the response, which will be 0x05 instead of 0x01 and then instead of sending the CMD41 command, send a CMD1 command to complete the initialization process.

        ; Expect status response $01 (not initialized)
        cmp     #$01
        bne     .initfailed0

        ; Read 32-bit return value, but ignore it
        jsr     sd_readbyte
        jsr     sd_readbyte
        jsr     sd_readbyte
        jsr     sd_readbyte


        lda     #$ff
        jsr     sd_writebyte

        lda     #$ff
        jsr     sd_writebyte

        lda     #$ff
        jsr     sd_writebyte

.cmd55  ; APP_CMD - required prefix for ACMD commands
        pump_and_write 8

        lda     #<sd_cmd55_bytes
        sta     zp_sd_address
        lda     #>sd_cmd55_bytes
        sta     zp_sd_address+1

        jsr     sd_sendcommand

        ; Expect status response $01 (not initialized)
        cmp     #$01
        bne     .initfailed0

.cmd41  ; APP_SEND_OP_COND - send operating conditions, initialize card
        pump_and_write 8

        lda     #<sd_cmd41_bytes
        sta     zp_sd_address
        lda     #>sd_cmd41_bytes
        sta     zp_sd_address+1

        jsr     sd_sendcommand

        ; Status response $00 means initialised
        cmp     #$00
        beq     .cmd58

        ; Otherwise expect status response $01 (not initialized)
        cmp     #$01
        bne     .initfailed0

        ; Not initialized yet, so wait a while then try again.
        ; This retry is important, to give the card time to initialize.

        ldx     #0
        ldy     #0
.delayloop
        dey
        bne     .delayloop
        dex
        bne     .delayloop

        jmp     .cmd55

.initfailed0:
        jmp     .initfailed

.cmd58:
        pump_and_write 8

        lda     #<sd_cmd58_bytes
        sta     zp_sd_address
        lda     #>sd_cmd58_bytes
        sta     zp_sd_address+1

        jsr     sd_sendcommand
        jsr     sd_readbyte
        jsr     sd_readbyte
        jsr     sd_readbyte
        jsr     sd_readbyte
;
.cmd16:
        pump_and_write 8

        lda     #<sd_cmd16_bytes
        sta     zp_sd_address
        lda     #>sd_cmd16_bytes
        sta     zp_sd_address+1

        jsr     sd_sendcommand



.initialized
        .ifdef  DEBUGSD
        lda     #'Y'
        macro_oscall oscPutC
        .endif
        clc
        rts

.initfailed
        .ifdef  DEBUGSD
        lda     #'X'
        macro_oscall oscPutC
        macro_oscall oscPutCrLf
        .endif

        sec
        rts


sd_cmd0_bytes
        .byte   $40, $00, $00, $00, $00, $95
sd_cmd8_bytes
        .byte   $48, $00, $00, $01, $aa, $87
sd_cmd55_bytes
        .byte   $77, $00, $00, $00, $00, $01
sd_cmd41_bytes
        .byte   $69, $40, $00, $00, $00, $01

sd_cmd58_bytes
        .byte   $7A,0,0,0,0,$1  ;
sd_cmd16_bytes
        .byte   $50,0,0,2,0,$1  ; set block length to 512bytes




sd_readbyte:
        phy
        ldy     #SD_CS_INDEX
        jsr     k_SPI_Recv_Byte
        ply
        rts


sd_writebyte:
        phy
        ldy     #SD_CS_INDEX
        jsr     k_SPI_Send_Byte
        ply
        rts


sd_waitresult:
        phy
        phx
        ldx     #$20
.loopo:
        ldy     #0
        ; Wait for the SD card to return something other than $ff
.loop:
        jsr     sd_readbyte
        cmp     #$ff
        bne     .done
        dey
        bne     .loop
        dex
        bne     .loopo
.done:
        plx
        ply
        rts


sd_sendcommand:
        .ifdef  DEBUGSD
        lda     #'c'
        macro_oscall oscPutC
        ldx     #0
        lda     (zp_sd_address,x)
        macro_oscall oscPutHexByte
        .endif
        ; send some dummy bytes to let sd get the timing

        pump_and_write 8


        ldy     #0
        lda     (zp_sd_address),y; command byte
        jsr     sd_writebyte
        ldy     #1
        lda     (zp_sd_address),y; data 1
        jsr     sd_writebyte
        ldy     #2
        lda     (zp_sd_address),y; data 2
        jsr     sd_writebyte
        ldy     #3
        lda     (zp_sd_address),y; data 3
        jsr     sd_writebyte
        ldy     #4
        lda     (zp_sd_address),y; data 4
        jsr     sd_writebyte
        ldy     #5
        lda     (zp_sd_address),y; crc
        jsr     sd_writebyte

        jsr     sd_waitresult
        .ifdef  DEBUGSD
        ; Debug print the result code
        pha
        macro_oscall oscPutHexByte
        pla                     ; restore result code
        .endif
        rts


sd_readsector:
        ; Read a sector from the SD card.  A sector is 512 bytes.
        ;
        ; Parameters:
        ;    zp_sd_currentsector   32-bit sector number
        ;    zp_sd_address         address of buffer to receive data
        ;


        ; send some dummy bytes to let sd get the timing

        pump_and_write 8



        ; Command 17, arg is sector number, crc not checked
        lda     #$51            ; CMD17 - READ_SINGLE_BLOCK
        jsr     sd_writebyte
        lda     zp_sd_currentsector+3; sector 24:31
        jsr     sd_writebyte
        lda     zp_sd_currentsector+2; sector 16:23
        jsr     sd_writebyte
        lda     zp_sd_currentsector+1; sector 8:15
        jsr     sd_writebyte
        lda     zp_sd_currentsector; sector 0:7
        jsr     sd_writebyte
        lda     #$01            ; crc (not checked)
        jsr     sd_writebyte

        jsr     sd_waitresult
        cmp     #$00
        bne     .fail

        ; wait for data - TODO time out after about 8 tries?
        jsr     sd_waitresult
        cmp     #$fe
        bne     .fail

        ; Need to read 512 bytes - two pages of 256 bytes each
        jsr     .readpage
        inc     zp_sd_address+1
        jsr     .readpage
        dec     zp_sd_address+1

        ; ignore crc bytes
        jsr     sd_readbyte
        jsr     sd_readbyte
        clc
        rts


.fail
        .ifdef  DEBUGSD
        lda     #'s'
        macro_oscall oscPutC
        lda     #':'
        macro_oscall oscPutC
        lda     #'f'
        macro_oscall oscPutC
        .endif

        sec
        rts
; .failloop
;         jmp     .failloop


.readpage
        ; Read 256 bytes to the address at zp_sd_address
        ldy     #0
.readloop
        jsr     sd_readbyte
        sta     (zp_sd_address),y
        iny
        bne     .readloop
        rts



