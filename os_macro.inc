; helper for storing a symbol into a vector word

; macro_store_symbol2word symbol,word
        .macro  macro_store_symbol2word,symbol,word
        lda     #<\symbol
        sta     \word
        lda     #>\symbol
        sta     \word+1
        .endm

; macro_PutZArg0 symbol
        .macro  macro_putzarg0,symbol
        lda     #<\symbol
        sta     osCallArg0
        lda     #>\symbol
        sta     osCallArg0+1
        macro_oscall oscPutZArg0
        .endm
; os call simplifier
        .macro  macro_oscall,call
        phx
        phy
        ldx     #\call
        jsr     osCall
        ply
        plx
        .endm

; os return to monitor
        .macro  os_monitor_return
        ldx     #oscMonitorReturn
        jmp     osCall
        .endm

; simple print immediate
        .macro  macro_print,text
        macro_store_symbol2word .lable\@,osCallArg0
        macro_oscall oscPutZArg0
        jmp     .continue\@
.lable\@:
        .string \text
.continue\@:
        .endm

; simple print one char
        .macro  macro_print_c,char
        lda     #\char
        macro_oscall oscPutC
        .endm

; i2c helper macro (writes up to 4 bytes to address - sends a start and stop bit)
; set byte2 etc as -1 to skip

        .macro  macro_i2c_write_to,address,errorhandler,byte1,byte2,byte3,byte4
        lda     #\address
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Write; writing (so no change to lsb)
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .error\@
        ; send command
        ifge    \byte1
        lda     #\byte1
        ldx     #0
        jsr     os_i2c_write_byte
        bcs     .error\@
        endif
        ; send additional date -1 means skip this byte
        ifge    \byte2
        lda     #\byte2
        ldx     #0
        jsr     os_i2c_write_byte
        bcs     .error\@
        endif
        ; send additional date -1 means skip this byte
        ifge    \byte3
        lda     #\byte3
        ldx     #0
        jsr     os_i2c_write_byte
        bcs     .error\@
        endif
        ; send additional date -1 means skip this byte
        ifge    \byte4
        lda     #\byte4
        ldx     #0
        jsr     os_i2c_write_byte
        bcs     .error\@
        endif

        bra     .noerror\@

.error\@:
        jmp     \errorhandler
.noerror\@:
        jsr     os_i2c_stop_cond;send a stop
        .endm


; i2c helper macro (writes up to 4 bytes to address - sends a start and stop bit)
; set byte2 etc as -1 to skip

        .macro  macro_i2c_write_reg_buf,address,errorhandler,byte1,buffer
        lda     #\address
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Write; writing (so no change to lsb)
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .error\@
        ; send command
        lda     #\byte1
        ldx     #0
        jsr     os_i2c_write_byte
        bcs     .error\@
        ; send additional date -1 means skip this byte
        lda     \buffer
        ldx     #i2c_F_SEND_STOP
        jsr     os_i2c_write_byte
        bcc     .noerror\@

.error\@:
        jmp     \errorhandler
.noerror\@:
;         jsr os_i2c_stop_cond               ;send a stop
        .endm




; i2c helper macro (reads up to arg bytes from address to buffer - sends a start and stop bit and acks)
; set byte2 etc as -1 to skip
; set stop to anything >-1 to send stop bit
        .macro  macro_i2c_read_to,address,errorhandler,buffer,bytes,stop
; address
        lda     #\address
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Read
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .error\@
        ;read some bytes
        ldy     #0
.readloop\@:
        phy
        ldx     #i2c_F_SEND_ACK
        jsr     os_i2c_read_byte
        ply
        bcs     .error\@
        sta     \buffer,y
        iny
        cpy     #\bytes
        bne     .readloop\@
        bra     .noerror\@

.error\@:
        jmp     \errorhandler
.noerror\@:
        ifge    \stop
        jsr     os_i2c_stop_cond;send a stop
        endif
        .endm

; i2c helper macro (reads up to arg bytes from address to buffer - sends a start and stop bit and acks)
; set stop to anything >-1 to send stop bit
; send a nack always as on last read
        .macro  macro_i2c_read_to_nack,address,errorhandler,buffer,bytes,stop
; address
        lda     #\address
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Read
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .error\@
        ;read some bytes
        ldy     #0
.readloop\@:
        phy
        ldx     #i2c_F_SEND_ACK
        cpy     #\bytes-1
        bne     .notend\@
        ldx     #i2c_F_SEND_NACK
.notend\@:
        jsr     os_i2c_read_byte
        ply
        bcs     .error\@
        sta     \buffer,y
        iny
        cpy     #\bytes
        bne     .readloop\@
        bra     .noerror\@

.error\@:
        jmp     \errorhandler
.noerror\@:
        ifge    \stop
        jsr     os_i2c_stop_cond;send a stop
        endif
        .endm

; i2c helper macro (writes up to arg bytes from address to buffer - sends a start and stop bit)

        .macro  macro_i2c_write_from,address,errorhandler,buffer,bytes
; address
        lda     #\address
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Write
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .error\@
        ;read some bytes
        ldy     #0
.readloop\@:
        ldx     #0
        lda     \buffer,y
        jsr     os_i2c_write_byte
        bcs     .error\@
        iny
        cpy     #\bytes
        bne     .readloop\@
        bra     .noerror\@

.error\@:
        jmp     \errorhandler
.noerror\@:
        jsr     os_i2c_stop_cond;send a stop
        .endm

        ; adds reg 1 to reg 0 storing result in reg 0
        ; BIG endian
        .macro  macro_32_bit_add,reg0,reg1
        clc
        cld                     ; just in case!
        lda     \reg1+3
        adc     \reg0+3
        sta     \reg0+3

        lda     \reg1+2
        adc     \reg0+2
        sta     \reg0+2

        lda     \reg1+1
        adc     \reg0+1
        sta     \reg0+1

        lda     \reg1
        adc     \reg0
        sta     \reg0

        .endm

        .macro  macro_32_bit_copy,reg0,reg1
        lda     \reg0
        sta     \reg1
        lda     \reg0+1
        sta     \reg1+1
        lda     \reg0+2
        sta     \reg1+2
        lda     \reg0+3
        sta     \reg1+3
        .endm

        .macro  macro_32_shift_left,reg,n
        ldy     #\n
.loop\@:
        asl     \reg+3
        rol     \reg+2
        rol     \reg+1
        rol     \reg
        dey
        bne     .loop\@
        .endm

        .macro  macro_32_shift_right,reg,n
        ldy     #\n
.loop\@:
        lsr     \reg
        ror     \reg+1
        ror     \reg+2
        ror     \reg+3
        dey
        bne     .loop\@
        .endm

