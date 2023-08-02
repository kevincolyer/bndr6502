; adapted from https://github.com/7west/6502/blob/main/i2ctemp.s
; PORT DEFINITIONS
VIA0_PORTA=VIA0+1
VIA0_DDRA=VIA0+3


; moved to os_constants
; NACK is high (1) ACK is low (0)
; i2c_F_SEND_ACK=0
; i2c_F_SEND_NACK=1
; i2c_F_SEND_START=2
; i2c_F_SEND_STOP=4

; SDA [7] and SCL [0]
; a 1 = LOW, 1 means OUTPUT, and PORT is set to LOW
; a 0 = HIGH, 0 means INPUT => High-Z w/pull-up
i2c_SDA_pin=%10000000
i2c_SCL_pin=%00000001


i2c_pins_read=0
i2c_pins_write=(i2c_SDA_pin|i2c_SCL_pin)

i2c_Master_Write=0
i2c_Master_Read=1

; moved to os_constants
; E_i2c_OK=0
; E_i2c_TIMEOUT=1
; E_i2c_NACK=2
; E_i2c_READBYTE=3
; E_i2c_WRITEBTE=4
; E_i2c_ARBITRATIONLOST=5
;         ; preserves c sets m
;         .macro  macro_i2c_set_port_to_read
;         lda     #i2c_pins_read
;         sta     VIA0_DDRA
;         .endm
;
;         ; preserves c sets m
;         .macro  macro_i2c_set_port_to_write
;         lda     #i2c_pins_write
;         sta     VIA0_DDRA
;         .endm

; a-> holds time to wait - A x 10ms
; keeps x,y?
i2c_wait10ms:
        sta     os_rtc_countdown
        phx
.waitloop:
        stz     osR0            ; this just helps the watchdog not reset the board! (rw activity)
        jmp     k_ACIA_getc     ; get out

        bcs     .return
        lda     os_rtc_countdown
        bne     .waitloop
.return:
        plx
        rts

; code from https://en.wikipedia.org/wiki/I%C2%B2C

; Timings 100 Khz bus on a 2Mhz clock is 20 clocks per duty cycle
i2c_delay:
        ; jsr=6 cycles
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        ; rts=6 cycles
        rts

; bool read_SCL(void);  // Return current level of SCL line, 0 or 1
; c <- bit read
i2c_read_SCL:
        ;macro_i2c_set_port_to_read
        lda     #i2c_SCL_pin
        trb     VIA0_DDRA
        lda     VIA0_PORTA
        lsr                     ; because SCL is bit 0 -> c
        rts
        ; bool read_SDA(void);  // Return current level of SDA line, 0 or 1
        ; c <- bit read
i2c_read_SDA:
        ;macro_i2c_set_port_to_read
        lda     #i2c_SDA_pin
        trb     VIA0_DDRA
        lda     VIA0_PORTA
        asl                     ; because SDA is bit 7 -> c
        rts
        ; void set_SCL(void);   // Do not drive SCL (set pin high-impedance)
i2c_set_SCL:
        ; c -> bit to write
        ;macro_i2c_set_port_to_write
        lda     #i2c_SCL_pin
        trb     VIA0_DDRA
        trb     VIA0_PORTA
        rts

; void clear_SCL(void); // Actively drive SCL signal low
i2c_clear_SCL:
; c -> bit to write
        ;macro_i2c_set_port_to_write
        lda     #i2c_SCL_pin
        trb     VIA0_PORTA
        tsb     VIA0_DDRA
        rts
        ; void set_SDA(void);   // Do not drive SDA (set pin high-impedance)
i2c_set_SDA:
        ; c -> bit to write
        ;macro_i2c_set_port_to_write
        lda     #i2c_SDA_pin
        trb     VIA0_DDRA
        trb     VIA0_PORTA
        rts

; void clear_SDA(void); // Actively drive SDA signal low
i2c_clear_SDA:
; c -> bit to write
        ;macro_i2c_set_port_to_write
        lda     #i2c_SDA_pin
        trb     VIA0_PORTA
        tsb     VIA0_DDRA
        rts



i2c_arbitration:
        ; needed if multi controller system (not implimented)
        rts

i2c_clock_stretch:
        ; A <- timeout error if it occurs
        ; c <- set if error
        ; on error pulls return stack address and rts to PREVIOUS caller.

;     while (read_SCL() == 0) { // Clock stretching
        ldx     #20             ; to allow approx 0.2ms for clock streching before timeout
.clockstretch:
        jsr     i2c_read_SCL
        bcs     .done
        jsr     i2c_delay
        dex
        bne     .clockstretch
        ;       // timeout
        pla
        pla                     ; remove return address from stack - we are totally bailing out
        lda     #E_i2c_TIMEOUT
        sec
.done:
        rts

i2c_init:
        stz     VIA0_DDRA       ; set to read mode to release lines
        stz     VIA0_PORTA      ; clear any data writing to 0 (i2c does not need us to drive lines hi - the resistors do that. We only drive low.)
        stz     i2c_v_started
        stz     i2c_v_error_code
        stz     i2c_v_byte
        stz     i2c_v_flags
        stz     i2c_v_bit
        rts
        ;
i2c_release:
        jsr     i2c_read_SDA
        jsr     i2c_read_SCL
        rts
        ; void i2c_start_cond(void)
i2c_start_cond:
        ;        stz i2c_v_error_code ; set to E_i2c_OK
        ; {
        lda     i2c_v_started
        beq     .dostart
        ;   if (started) {
        ;     // if started, do a restart condition
        ;     // set SDA to 1
        ;macro_i2c_set_port_to_write
        ;     set_SDA();
        jsr     i2c_set_SDA
        ;     I2C_delay();
        jsr     i2c_delay
        ;     set_SCL();
        jsr     i2c_set_SCL
        ;     while (read_SCL() == 0) { // Clock stretching
        jsr     i2c_clock_stretch
        ;     }


;     // Repeated start setup time, minimum 4.7us
;     I2C_delay();
        jsr     i2c_delay
;   }
.dostart
;         ;macro_i2c_set_port_to_read
;         ;   if (read_SDA() == 0) {
;         jsr     i2c_read_SDA
;         bcs     .skiperror
;         ;     arbitration_lost();
;         jsr     i2c_arbitration
;
; ;   }
; .skiperror
;
        ;macro_i2c_set_port_to_write
        ;   // SCL is high, set SDA from 1 to 0.
        ;   clear_SDA();
        jsr     i2c_clear_SDA
        ;   I2C_delay();
        jsr     i2c_delay
        ;   clear_SCL();
        jsr     i2c_clear_SCL
        ;   started = true;
        lda     #1
        sta     i2c_v_started
        clc
        rts
        ; }
        ;
i2c_stop_cond:
        ; void i2c_stop_cond(void)
        ; {
        ;macro_i2c_set_port_to_write
        ;   // set SDA to 0
        ;   clear_SDA();
        jsr     i2c_clear_SDA
        ;   I2C_delay();
        jsr     i2c_delay
        ;   set_SCL();
        jsr     i2c_set_SCL
        ;   // Clock stretching
        jsr     i2c_clock_stretch
        ;
        ;   // Stop bit setup time, minimum 4us
        ;   I2C_delay();
        jsr     i2c_delay
        ;
        ;   // SCL is high, set SDA from 0 to 1
        ;   set_SDA();
        jsr     i2c_set_SDA
        ;   I2C_delay();
        jsr     i2c_delay
        ;
        ;         ;macro_i2c_set_port_to_read
        ;         jsr     i2c_read_SDA
        ;         bcs     .skiparbitration
        ;         ;   if (read_SDA() == 0) {
        ;         ;     arbitration_lost();
        ;         ;   }
        ;         jsr     i2c_arbitration
        ; .skiparbitration:
        ;         ;
        ;   started = false;
        stz     i2c_v_started
        rts
        ; }
        ;
        ; // Write a bit to I2C bus  c -> set is high (keeps Y, destroys A,X)
i2c_write_bit:
        ; void i2c_write_bit(bool bit)
        ; {
        ;   if (bit) {
        ;     set_SDA();
        ;   } else {
        ;     clear_SDA();
        ;   }
        ;macro_i2c_set_port_to_write
        ;         php
        bcs     .set_sda
        ;nop
        ;nop
        jsr     i2c_clear_SDA
        bra     .delay
.set_sda:
        ;dec     i2c_v_bit
        jsr     i2c_set_SDA
        ;
        ;   // SDA change propagation delay
        ;   I2C_delay();
.delay
        jsr     i2c_delay
        ;   // Set SCL high to indicate a new valid SDA value is available
        ;   set_SCL();
        jsr     i2c_set_SCL
        ;
        ;   // Wait for SDA value to be read by target, minimum of 4us for standard mode
        ;   I2C_delay();
        jsr     i2c_delay
        ;   while (read_SCL() == 0) { // Clock stretching
        jsr     i2c_clock_stretch
        ;     // You should add timeout to this loop
        ;   }
        ;
        ;   // SCL is high, now data is valid
        ;   // If SDA is high, check that nobody else is driving SDA
        ;macro_i2c_set_port_to_read
        ;   if (bit && (read_SDA() == 0)) {
        ;     arbitration_lost();
        ;         plp
        ;         ;lda     i2c_v_bit
        ;         bcc     .finish
        ;         jsr     i2c_read_SDA
        ;         bcs     .finish
        ;         jsr     i2c_arbitration
        ;   }
.finish:
        ;   // Clear the SCL to low in preparation for next change
        ;   clear_SCL();
        jsr     i2c_clear_SCL
        jsr     i2c_delay
        rts
        ; }
        ;
        ; // Read a bit from I2C bus    c <- returned in carry (keeps Y,X, destroys A)
        ; bool i2c_read_bit(void)
i2c_read_bit:
        ; {
        ;   bool bit;
        ;macro_i2c_set_port_to_read
        ;
        ;   // Let the target drive data
        ;   set_SDA();
        jsr     i2c_set_SDA
        ;
        ;   // Wait for SDA value to be written by target, minimum of 4us for standard mode
        ;   I2C_delay();
        jsr     i2c_delay
        ;
        ;   // Set SCL high to indicate a new valid SDA value is available
        ;   set_SCL();
        jsr     i2c_set_SCL
        ;
        ;   while (read_SCL() == 0) { // Clock stretching
        ;     // You should add timeout to this loop
        ;   }
        jsr     i2c_clock_stretch
        ;
        ;   // Wait for SDA value to be written by target, minimum of 4us for standard mode
        ;   I2C_delay();
        jsr     i2c_delay
        ;   // SCL is high, read out bit
        ;   bit = read_SDA();
        jsr     i2c_read_SDA
        php                     ; store carry for a moment
        ;
        ;   // Set SCL low in preparation for next operation
        ;   clear_SCL();
        jsr     i2c_clear_SCL
        ;   return bit;
        plp
        rts
        ; }
        ;

        ; i2c_F_ACK=0
        ; i2c_F_NACK=1
        ; // Write a byte to I2C bus. Return 0 if ack by the target.
        ; A -> byte to write
        ; X -> bit 0 send_start bit 1 send stop
        ; preserves Y
        ; c <- set = nack, clear = ack
        ; bool i2c_write_byte(bool send_start,
        ;                     bool send_stop,
        ;                     unsigned char byte)
i2c_write_byte:
        ; {
        ;   unsigned bit;
        ;   bool     nack;
        stx     i2c_v_flags
        sta     i2c_v_byte
        .ifdef  debug
        txa                     ; debug
        jmp     k_ACIA_putc_Hex_Byte;  macro_oscall oscPutHexByte; debug
        lda     i2c_v_byte      ; debug
        jmp     k_ACIA_putc_Hex_Byte; macro_oscall oscPutHexByte; debug
        lda     #SPACE
        jmp     k_ACIA_putc     ;macro_oscall oscPutC; debug
        .endif
        ;   if (send_start) {
        ;     i2c_start_cond();
        ;   }
        lda     i2c_v_flags
        and     #i2c_F_SEND_START
        beq     .writebyte
        jsr     i2c_start_cond

;   for (bit = 0; bit < 8; ++bit) {
;     i2c_write_bit((byte & 0x80) != 0);
;     byte <<= 1;
;   }
.writebyte:
        sec
        rol     i2c_v_byte      ;shift sentinal bit in and first bit out
.writebitloop:
        jsr     i2c_write_bit   ; carry holds bit to write
        asl     i2c_v_byte      ; shift into carry
        bne     .writebitloop   ; completes when sentinal bit shifts out
        ;
        ;   nack = i2c_read_bit();
        jsr     i2c_read_bit
        php                     ; save ack or nack on the stack
        ;
        lda     i2c_v_flags
        and     #i2c_F_SEND_STOP
        beq     .return
        ;   if (send_stop) {
        ;     i2c_stop_cond();
        jsr     i2c_stop_cond
        ;   }
        ;
        ;   return nack;
.return:
        plp                     ; restore c from stack
        rts
        ; }
        ;
        ; // Read a byte from I2C bus
        ; unsigned char i2c_read_byte(bool nack, bool send_stop)

; X -> send ack or nack | send stop
; A <- byte read
; preserves Y
i2c_read_byte:
; {
;   unsigned char byte = 0;
;   unsigned char bit;
        lda     #1              ; seed byte with sentinal bit
        sta     i2c_v_byte
        stx     i2c_v_flags     ; store signalling info from x
        ;   for (bit = 0; bit < 8; ++bit) {
        ;     byte = (byte << 1) | i2c_read_bit();
        ;   }
        ;
.readbit:
        jsr     i2c_read_bit
        rol     i2c_v_byte      ; will be 0 for 7 more times till sentinal bit
        bcc     .readbit
        ; done reading - what do we send now?
        lda     i2c_v_flags     ; get flags
        ;   i2c_write_bit(nack);
        ; check ack or nack
        lsr                     ; in lsb (c = 1 => nack 0 => ack)
        jsr     i2c_write_bit   ;     write bit in carry
        ;   if (send_stop) {
        ;     i2c_stop_cond();
        ;   }
        lda     i2c_v_flags
        and     #i2c_F_SEND_STOP
        beq     .return
        jsr     i2c_stop_cond
        ;
        ;   return byte;
.return:
        lda     i2c_v_byte
        clc
        .ifdef  debug
        jmp     k_ACIA_putc_Hex_Byte; macro_oscall oscPutHexByte; debug
        .endif
        rts
