        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"





        ; userLowMem - origin of user low mem space ~$600 to userStart
        .org    userStart       ; expected org

main:
        ; load monitor command to monitor
        macro_store_symbol2word LCDInitCmd,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd3,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd4,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd5,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd6,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd7,osCallArg0
        macro_oscall oscMonitorAddCmd

        jsr     os_i2c_init

        ; back to monitor
        os_monitor_return




LCDInitCmd:
        .word   LCDInit_cmd
        .word   LCDInit
        .word   LCDInit_help
LCDInit_cmd:
        .byte   "2",0
LCDInit_help:
        .string "2-I2C test init LCD",CR,LF

testcmd3:
        .word   test_lcd_panel_cmd3_cmd
        .word   test_lcd_panel_cmd3
        .word   test_lcd_panel_cmd3_help
test_lcd_panel_cmd3_cmd:
        .byte   "3",0
test_lcd_panel_cmd3_help:
        .byte   "3-test printing to lcd panel",CR,LF,0

testcmd4:
        .word   test_dht20_cmd4_cmd
        .word   test_dht20_cmd4
        .word   test_dht20_cmd4_help
test_dht20_cmd4_cmd:
        .byte   "4",0
test_dht20_cmd4_help:
        .byte   "4-test DHT sensor",CR,LF,0

testcmd5:
        .word   test_bma150_cmd_cmd
        .word   test_bma150_cmd
        .word   test_bma150_cmd_help
test_bma150_cmd_cmd:
        .byte   "5",0
test_bma150_cmd_help:
        .byte   "5-test BMA150 sensor",CR,LF,0

testcmd6:
        .word   test_rtc_cmd_cmd
        .word   test_rtc_cmd
        .word   test_rtc_cmd_help
test_rtc_cmd_cmd:
        .byte   "6",0
test_rtc_cmd_help:
        .byte   "6-read date RTC module",CR,LF,0

testcmd7:
        .word   test_set_rtc_cmd_cmd
        .word   test_set_rtc_cmd
        .word   test_set_rtc_cmd_help
test_set_rtc_cmd_cmd:
        .byte   "7",0
test_set_rtc_cmd_help:
        .byte   "7-set date RTC module",CR,LF,0


test_lcd_panel3:
        .string "enter a test message to print to lcd",CR,LF
test_lcd_panel4:
        .string "printing to lcd...",CR,LF

test_lcd_panel_cmd3:
        ;ask for a message to print
        macro_store_symbol2word test_lcd_panel3,osCallArg0
        macro_oscall oscPutZArg0



        macro_oscall oscCleanInputBuf
        lda     #80
        sta     osCallArg0
        macro_oscall oscLineEditInput

        ; print it
        macro_store_symbol2word test_lcd_panel4,osCallArg0
        macro_oscall oscPutZArg0

        jsr     os_i2c_init
        jsr     lcd_clear       ; takes too long?
        ;        jsr     lcd_home


        macro_store_symbol2word osInputBuffer,osR0


        jsr     lcd_print_buffz_r0

        os_monitor_return

;------------DHT20 humidity and temp sensor-------------------------
DHT20ID=$38
; read sequence: 1. address + write, $ac, $33, $00
;                2. address + read , await state byte from sensor
;                       if state  has hi bit 7 then try again - sensor is busy
;                       otherwise
;                               read 20 bits humiddity (2 bytes + nybble)
;                               nybble and 20 bit temp data
;                               final byte is CRC - send nack to avoid
; RH % is (reading/2^20)*100%
; T C  is (reading/2^20)*200-50


; see https://github.com/adafruit/Adafruit_AHTX0/blob/master/Adafruit_AHTX0.cpp and .h
; this is for same class of sensor and shows the need for soft reset and then calibration commands before reading.
; AHTX0_I2CADDR_DEFAULT=0x38   ;< AHT default i2c address
; AHTX0_I2CADDR_ALTERNATE=0x39 ;< AHT alternate i2c address
AHTX0_CMD_CALIBRATE=$E1         ;< Calibration command
AHTX0_CMD_TRIGGER=$AC           ;< Trigger reading command
AHTX0_CMD_SOFTRESET=$BA         ;< Soft reset command
AHTX0_STATUS_BUSY=$80           ;< Status bit for busy
AHTX0_STATUS_CALIBRATED=$08     ;< Status bit for calibrated





test_dht20_cmd4:
        jsr     os_i2c_init     ; init the i2c bus and clear variables
        ;         ;         ;jsr $8f0e   ; reinit the rtc
        ;         ; initialise sensor
        ;         lda     #DHT20ID
        ;         asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ;         ora     #i2c_Master_Write; writing (so no change to lsb)
        ;         ldx     #i2c_F_SEND_START
        ;         jsr     os_i2c_write_byte
        ;         bcc .skip1
        ;         jmp .dht20_i2c_error
        ;
        ; .skip1:
        ;         lda     #AHTX0_CMD_SOFTRESET
        ;         ldx     #0
        ;         jsr     os_i2c_write_byte
        ;         bcc     .skip2
        ;         jmp .dht20_i2c_error
        ; .skip2:
        ;         jsr     os_i2c_stop_cond
        ;         ; wait 40ms
        ;         lda     #4
        ;         jsr     os_i2c_wait10ms
        ;         ; ask sensor to calibrate
        lda     #$4
        sta     osCallArg0      ; countdown for repeated calibrations
.calibrate:
        ; address
        ; ask for status
        macro_i2c_write_to DHT20ID,.dht20_i2c_error, $71,-1,-1,-1
        lda     #1
        jsr     os_i2c_wait10ms

        ; read a status byte
        macro_i2c_read_to DHT20ID,.dht20_i2c_error,.sensorreading,1,-1; read 3 bytes and send a stop
        ldx     #i2c_F_SEND_NACK
        jsr     os_i2c_read_byte; tell sensor to stop sending
        jsr     os_i2c_stop_cond

        lda     .sensorreading
        and     #$18
        cmp     #$18
        beq     .resetDHT20     ; need to initialise sensor
        jmp     .readout_sensor
.resetDHT20:
        ; see https://github.com/RobTillaart/DHT20/blob/master/DHT20.cpp for reset code. Do for all 3 regs 1b,1c, 1e
        ; reset reg 1b
        macro_i2c_write_to DHT20ID,.dht20_i2c_error,$1b,0,0,-1
        lda     #1
        jsr     os_i2c_wait10ms

        macro_i2c_read_to_nack DHT20ID,.dht20_i2c_error,.sensorreading,3,1; read 3 bytes and send a stop
        jsr     os_i2c_release  ; brutally tell sensor to stop writing...
        lda     #1
        jsr     os_i2c_wait10ms

        lda     #$1b|$b0
        sta     .sensorreading
        macro_i2c_write_from DHT20ID,.dht20_i2c_error,.sensorreading,3
        lda     #1
        jsr     os_i2c_wait10ms

        ; reset reg 1c ---------------------------------------
        macro_i2c_write_to DHT20ID,.dht20_i2c_error,$1c,0,0,-1
        lda     #1
        jsr     os_i2c_wait10ms

        macro_i2c_read_to_nack DHT20ID,.dht20_i2c_error,.sensorreading,3,1; read 3 bytes and send a stop
        jsr     os_i2c_release  ; brutally tell sensor to stop writing...
        lda     #1
        jsr     os_i2c_wait10ms

        lda     #$1c|$b0
        sta     .sensorreading
        macro_i2c_write_from DHT20ID,.dht20_i2c_error,.sensorreading,3
        lda     #1
        jsr     os_i2c_wait10ms

        ; reset reg 1e ---------------------------------------
        macro_i2c_write_to DHT20ID,.dht20_i2c_error,$1e,0,0,-1
        lda     #1
        jsr     os_i2c_wait10ms

        macro_i2c_read_to_nack DHT20ID,.dht20_i2c_error,.sensorreading,3,1; read 3 bytes and send a stop
        jsr     os_i2c_release  ; brutally tell sensor to stop writing...
        lda     #1
        jsr     os_i2c_wait10ms

        lda     #$1e|$b0
        sta     .sensorreading
        macro_i2c_write_from DHT20ID,.dht20_i2c_error,.sensorreading,3
        lda     #1
        jsr     os_i2c_wait10ms

        dec     osCallArg0
        bmi     .readout_sensor
        jmp     .calibrate

.dht20_i2c_error:
        pha
        jsr     os_i2c_stop_cond
        pla
        macro_oscall oscPutHexByte
        macro_store_symbol2word .dht20_err_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return
        ; Read data from sesnor
.readout_sensor:
        lda     #8              ; wait 80ms for reading to take place
        jsr     os_i2c_wait10ms
.awaitnotbusy
        ; loop till ready...
        ; address
        macro_i2c_write_to DHT20ID,.dht20_i2c_error,AHTX0_CMD_TRIGGER,$33,0,-1
        ; wait for at least 20ms
        lda     #2
        jsr     os_i2c_wait10ms
        ; prepare to read

.ask_for_reading:

;address
        lda     #DHT20ID
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Read; writing (so no change to lsb)
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .dht20_i2c_error

; get byte of reading
        ldx     #i2c_F_SEND_NACK
        jsr     os_i2c_read_byte
        bcs     .dht20_i2c_error
        ; check device is ready to give reading
        bpl     .read_more      ; not busy so read more
        jsr     os_i2c_stop_cond; yes busy
        bra     .awaitnotbusy   ; keep asking

; now we can read all the yummy data...
.read_more:
        macro_i2c_read_to DHT20ID,.dht20_i2c_error,.sensorreading,7,1
        ; stop transmission - we are done
        jsr     os_i2c_release
        jmp     .interpret_reading; what did we get?

.dht20_err_msg:
        .string " i2c error message reading DHT20",CR,LF

.dht20_reading_msg:
        .string " (humid temp) DHT20 reading",CR,LF

.sensorreading:
        .byte   0, 0,0,0,0,0,0,0


.interpret_reading:
;         ldy     #1              ; can skip status byte
; .loop:
;         lda     .sensorreading,y
;         phy
;         macro_oscall oscPutHexByte
;         ply
;         iny
;         cpy     #6              ; 7th byte is the crc - can skip that
;         bne     .loop


        ; temp
        lda     .sensorreading+3
        and     #$0f
        sta     osOutputBuffer+3
        lda     .sensorreading+4
        sta     osOutputBuffer+4
        lda     .sensorreading+5
        sta     osOutputBuffer+5
        ; humidity
        lda     .sensorreading+1
        sta     osOutputBuffer+0
        lda     .sensorreading+2
        sta     osOutputBuffer+1
        lda     .sensorreading+3
        sta     osOutputBuffer+2
        ldy     #4
.rolloop:
        lsr     osOutputBuffer
        ror     osOutputBuffer+1
        ror     osOutputBuffer+2
        dey
        bne     .rolloop

        ldy     #0
.printloop:
        lda     osOutputBuffer,y
        macro_oscall oscPutHexByte
        iny
        cpy     #3
        bne     .skipemitspace
        lda     #SPACE
        macro_oscall oscPutC

.skipemitspace:
        cpy     #6
        bne     .printloop

        macro_store_symbol2word .dht20_reading_msg,osCallArg0
        macro_oscall oscPutZArg0

        stz     osR0
        lda     osOutputBuffer+3
        sta     osR0+1
        lda     osOutputBuffer+4
        sta     osR0+2
        lda     osOutputBuffer+5
        sta     osR0+3

        ; mult by 200 /div 2^20 sub 50 = 2x then 100x then -50 = 4x store 8x store add to self twice more add store. div by 2^20 then sub
        ;macro_32_shift_left osR0,1 ; x2
        ;
        macro_32_shift_left osR0,2; x4
        ;jsr print32bithex               ; correct
        macro_32_bit_copy osR0,osR2

        macro_32_shift_left osR0,3; x 8
        macro_32_bit_copy osR0,osCallArg0
        ;jsr print32bithex               ; correct
        ; add twice
        macro_32_bit_add osR0,osCallArg0
        ;jsr print32bithex
        macro_32_bit_add osR0,osCallArg0
        ;jsr print32bithex
        ; add x4
        macro_32_bit_add osR0,osR2
        ;jsr print32bithex
        macro_32_shift_right osR0,19; div 2^20
        ;jsr print32bithex
        sec
        lda     osR0+3
        sbc     #50
        sta     osR0+3

        lda     osR0+2
        sbc     #0
        sta     osR0+2

        lda     osR0+1
        sbc     #0
        sta     osR0+1

        lda     osR0
        sbc     #0
        sta     osR0

; convert decminal
        lda     osR0+3
        sta     osCallArg1
        lda     osR0+2
        sta     osCallArg1+1
        ;
        stz     osCallArg2
        macro_store_symbol2word osOutputBuffer,osCallArg0
        macro_oscall oscWord2DecimalString
        macro_oscall oscPutZArg0

        macro_store_symbol2word .tempis,osCallArg0
        macro_oscall oscPutZArg0


;        jsr print32bithex


        os_monitor_return
.tempis:
        .string " degrees C"
; print32bithex:
;         ldy #0
; .printloop2:
;         lda osR0,y
;         macro_oscall oscPutHexByte
;         iny
;         cpy #4
;         bne .printloop2
;
;         macro_oscall oscPutCrLf
;         rts

;-------BMA150---------------------------------------------

BMA150ID=$76

; temp readings are from $fa to $fc
i2c_BMA150_temp_xlsb=$fc        ; only upper nybble is of interest
i2c_BMA150_temp_lsb=$fb
i2c_BMA150_temp_msb=$fa

i2c_BMA150_config_reg=$f5
i2c_BMA150_ctrl_meas_reg=$f4
i2c_BMA150_status_reg=$f3



test_bma150_cmd:
        jsr     os_i2c_init
        ;jsr $8f0e   ; reinit the rtc
        ; init sensor - send ctrl_meas  0xF4 to set mode
        ;  set up the temp. Pressure and Humidit - skip!
        ; ask sensor to prepare for reading
.bma150_config=%1010000         ; standby time 1000ms, no filter and no spi stuff
.bma150_ctrl_meas=%00100010     ; 1x temp over sampling, skip pressure; forced mode (e.g. on read 11 = normal means continuous)
        macro_i2c_write_to BMA150ID,.bma150_i2c_error,i2c_BMA150_config_reg,.bma150_config,i2c_BMA150_ctrl_meas_reg,.bma150_ctrl_meas

.await_reading
        lda     #1
        jsr     os_i2c_wait10ms

        lda     #BMA150ID
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Write; writing (so no change to lsb)
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .bma150_i2c_error

        lda     #i2c_BMA150_status_reg; status read
        sta     osCallArg0
        ldx     #i2c_F_SEND_STOP
        jsr     os_i2c_write_byte
        bcs     .bma150_i2c_error
        and     #%00001001      ; read bit 3 and bit 0
        bne     .await_reading


.ask_for_reading:
        macro_i2c_write_to BMA150ID,.bma150_i2c_error,i2c_BMA150_status_reg,-1,-1,-1; send register we want to read from

        macro_i2c_read_to_nack BMA150ID,.bma150_i2c_error,.bma150sensorreading,3,1; send a nack to end reading and a stop bit

        jsr     os_i2c_release
;         lsr     .bma150sensorreading+2
;         lsr     .bma150sensorreading+2
;         lsr     .bma150sensorreading+2
;         lsr     .bma150sensorreading+2
;         lda     .bma150sensorreading
        jmp     .interpret_reading

.bma150_i2c_error:
        pha
        jsr     os_i2c_stop_cond
        pla
        macro_oscall oscPutHexByte
        macro_store_symbol2word .bma150_err_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

.bma150_err_msg:
        .string " i2c error message reading BMA150",CR,LF

.bma150_reading_msg:
        .string " BMA150 reading",CR,LF

.bma150sensorreading:
        .byte   0,0,0,0,0,0,0,0,0

.interpret_reading:
; code for interpretting the reading - requires coefficiants digT1 T2 T3
; 0x88 / 0x89  dig_T1 [7:0] / [15:8]  unsigned short
; 0x8A / 0x8B  dig_T2 [7:0] / [15:8]  signed short
; 0x8C / 0x8D  dig_T3 [7:0] / [15:8]  signed short
; {
; BME280_S32_t var1, var2, T;
; var1 = ((((adc_T>>3) – ((BME280_S32_t)dig_T1<<1))) * ((BME280_S32_t)dig_T2)) >> 11;
; var2 = (((((adc_T>>4) – ((BME280_S32_t)dig_T1)) * ((adc_T>>4) – ((BME280_S32_t)dig_T1))) >> 12) *
; ((BME280_S32_t)dig_T3)) >> 14;
; t_fine = var1 + var2;
; T = (t_fine * 5 + 128) >> 8;
; return T;
; }

        ldy     #0              ; skip status byte
.loop:
        lda     .bma150sensorreading,y
        phy
        macro_oscall oscPutHexByte
        ply
        iny
        cpy     #3
        bne     .loop

        macro_store_symbol2word .bma150_reading_msg,osCallArg0
        macro_oscall oscPutZArg0


        os_monitor_return


;-------LCD-------------------------------------------------
LCD1602ID=$3e                   ; id of lcd device on i2c bus
Control_Last=0
Control_Follow=$80
i2c_Master_Write=0
i2c_Master_Read=1

; LCD1602ID
RS=$40  ; select register for instructions LCD1602ID 0 or data 1 (bit 6)
DATA=RS ; data mode requres rs 1
FSET=0  ; instruction set requires rs 0

LCDInit:
        jsr     os_i2c_init

        macro_store_symbol2word LCDInitStart_msg,osCallArg0
        macro_oscall oscPutZArg0

        clc
        lda     #LCD1602ID
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Write; writing (so no change to lsb)

        ; start bus and attn address
        ldx     #i2c_F_SEND_START
        jsr     os_i2c_write_byte
        bcs     .goterror

        ; send control byte
        lda     #(Control_Follow|FSET)
        ldx     #0
        jsr     os_i2c_write_byte; send control byte
        bcs     .goterror

        ; send data instruction for LCD
        ldx     #0
        lda     #%00111000      ; LCD Set 8-bit mode; 2-line display; 5x8 font
        jsr     os_i2c_write_byte; send data byte
        bcs     .goterror

        ; send control byte
        ldx     #0
        lda     #(Control_Follow|FSET)
        jsr     os_i2c_write_byte; send control byte
        bcs     .goterror

        ; send data instruction for LCD
        ;lda     #%00001110      ; Display on; cursor on; blink off
        ;         lda     #%00001111      ; Display on; cursor on; blink ON
        lda     #%00001101      ; Display on; cursor off; blink ON
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .goterror

        ; send control byte
        lda     #(Control_Follow|FSET)
        ldx     #0
        jsr     os_i2c_write_byte; send control byte
        bcs     .goterror

        ; send data instruction for LCD
        lda     #%00000110      ; Increment and shift cursor; don't shift display
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .goterror

        ; send control byte
        lda     #(Control_Follow|FSET)
        ldx     #0
        jsr     os_i2c_write_byte; send control byte
        bcs     .goterror

        ; send data instruction for LCD
        lda     #%00000001      ; Clear display
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .goterror

        ;----------------------------------------------------
        ; send text to LCD

        ;
        lda     #(Control_Last|DATA)
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .goterror

        lda     #"H"
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .goterror

        lda     #"i"
        ldx     #i2c_F_SEND_STOP
        jsr     os_i2c_write_byte; send data byte
        bcc     .allok

.goterror:
        pha
        macro_oscall oscPutCrLf
        pla
        macro_oscall oscPutHexByte
        macro_oscall oscPutCrLf

        macro_store_symbol2word LCDInitErr_msg,osCallArg0
        macro_oscall oscPutZArg0
        ;lda #E_i2c_NACK
        jsr     os_i2c_stop_cond
        jsr     os_i2c_release
        bra     .return
.allok:
        macro_oscall oscPutCrLf
        macro_store_symbol2word LCDInitOK_msg,osCallArg0
        macro_oscall oscPutZArg0
        lda     #E_i2c_OK
.return:
        os_monitor_return

LCDInitOK_msg:
        .string "init LCD OK",CR,LF
LCDInitStart_msg:
        .string "starting init LCD",CR,LF
LCDInitErr_msg:
        .string "init LCD error",CR,LF

lcdmsg:
        .byte   "Booting...",0


lcd_clear:
        lda     #%00000001      ; Clear display
        jmp     lcd_instruction

lcd_home:
        lda     #%00000010      ; home and reset shift
        jmp     lcd_instruction

lcd_goto:
        ora     #$80            ; flag for set datadistplay index set or'd with desired index
        jmp     lcd_instruction

lcd_instruction:
        sta     i2c_v_lcd_instruction; stash data away
        jsr     lcd_address_i2c
        bcs     .end            ; some error so quit
        lda     #(Control_Last|FSET)
        ldx     #0
        jsr     os_i2c_write_byte; send control byte
        ;bcs     .end
        lda     i2c_v_lcd_instruction; now ready to send data
        ldx     #i2c_F_SEND_STOP
        jsr     os_i2c_write_byte; send control data one byte only
.end:
        rts

lcd_address_i2c:
        lda     #LCD1602ID
        asl                     ; shift left by 1 lsb = 0 write and 1 for read
        ora     #i2c_Master_Write; writing (so no change to lsb)

        ; start bus and attn address
        ldx     #i2c_F_SEND_START
        jmp     os_i2c_write_byte


; send text to LCD
lcd_print_buffz_r0:
        ;start i2c and address lcd
        jsr     lcd_address_i2c
        bcs     .end            ; some error so quit

        ; tell lcd to expect char data
        lda     #(Control_Last|DATA)
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .end

        ldy     #0
.loop:
        lda     (osR0),y
        beq     .end
        ; send char data over i2c
        ldx     #0
        jsr     os_i2c_write_byte; send data byte
        bcs     .end
        iny
        bne     .loop
.end:
        jsr     os_i2c_stop_cond
        jmp     os_i2c_release

;--------------------------------------------------
; 02h  VL_seconds      VL  <seconds 00 to 59 coded in BCD>
; 03h  minutes         x  <minutes 00 to 59 coded in BCD>
; 04h  hours           x  x  <hours 00 to 23 coded in BCD>
; 05h  days            x  x  <days 01 to 31 coded in BCD>
; 06h  weekdays        x  x  x  x  x  <weekdays 0 to 6 in BCD>
; 07h  century_months  C  x  x  <months 01 to 12 coded in BCD>
; 08h  years  <years 00 to 99 coded in BCD>
RTCID=$51

test_rtc_cmd:

        macro_i2c_write_to RTCID,.rtc_i2c_error,$02,-1,-1,-1; ask to read from reg $02

        macro_i2c_read_to_nack RTCID,.rtc_i2c_error,.rtc_reading,7,1;read 7 bytes and finish with nack and stop


        ; mask off valitidy bit on seconds
        lda     .rtc_reading
        and     #$7f
        ; swap seconds and hours
        pha
        lda     .rtc_reading+2
        sta     .rtc_reading
        pla
        sta     .rtc_reading+2
        ; move dow to end
        lda     .rtc_reading+4
        sta     .rtc_reading+7
        ; move months to dow slot
        lda     .rtc_reading+5
        and     #$7f            ; mask of century bit
        sta     .rtc_reading+4
        ; set century
        lda     #$20
        bit     .rtc_reading+5
        bpl     .c21
        lda     #$19
.c21:
        sta     .rtc_reading+5

        ; set internal clock
        jsr     .set_bndr_rtc

        ; print!
        ldy     #0
.print_loop:
        lda     .rtc_reading,y
        macro_oscall oscPutHexByte
        cpy     #5              ; skip gap between centurys and years.
        beq     .skip
        lda     .rtc_seps,y
        macro_oscall oscPutC
.skip:
        iny
        cpy     #7
        bne     .print_loop

        ; print dow
        lda     .rtc_reading,y
        clc
        adc     .rtc_reading,y
        adc     .rtc_reading,y
        tax
        ldy     #3
.print_dow:
        lda     .dow_tab,x
        phx
        macro_oscall oscPutC
        plx
        inx
        dey
        bne     .print_dow

        macro_oscall oscPutCrLf

        jsr     rtc_date_func_rts

        os_monitor_return

.rtc_i2c_error:
        pha
        jsr     os_i2c_stop_cond
        pla
        macro_oscall oscPutHexByte
        macro_store_symbol2word .rtc_err_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

.rtc_err_msg:
        .string " i2c error message reading RTC",CR,LF

.rtc_reading:
        .byte   0,0,0,0,0,0,0,0,0
.rtc_seps:
        .byte   ":: //? "
.dow_tab:
        .byte   "SunMonTueWedThuFriSat"

; transfer rtc to interal clock
.set_bndr_rtc:
        sei
        lda     .rtc_reading+2
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_SECONDS

        lda     .rtc_reading+1
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_MINUTES

        lda     .rtc_reading
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_HOURS

        lda     .rtc_reading+3
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_DAY

        lda     .rtc_reading+4
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_MONTH

        lda     .rtc_reading+6
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_YEAR

        lda     .rtc_reading+5
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_CENTURY

        lda     .rtc_reading+7
;        macro_oscall oscBcd2Bin
        jsr     .bcd2bin
        sta     os_rtc_DOW
        cli
        rts

.bcd2bin:
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

rtc_date_func_rts:
        macro_store_symbol2word rtc_date_msg,osCallArg0
        macro_oscall oscPutZArg0

        lda     os_rtc_HOURS
        macro_oscall oscBinToBcd
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC

        lda     os_rtc_MINUTES
        macro_oscall oscBinToBcd
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC

        lda     os_rtc_SECONDS
        macro_oscall oscBinToBcd
        macro_oscall oscPutHexByte
        lda     #SPACE
        macro_oscall oscPutC

        lda     os_rtc_DAY
        macro_oscall oscBinToBcd
        macro_oscall oscPutHexByte
        lda     #'/'
        macro_oscall oscPutC

        lda     os_rtc_MONTH
        macro_oscall oscBinToBcd
        macro_oscall oscPutHexByte
        lda     #'/'
        macro_oscall oscPutC

        lda     os_rtc_YEAR
        macro_oscall oscBinToBcd
        macro_oscall oscPutHexByte

        macro_oscall oscPutCrLf
        rts

rtc_date_msg:
        .string "Internal clock reads: "
;--------------------------------------------------
; 02h  VL_seconds      VL  <seconds 00 to 59 coded in BCD>
; 03h  minutes         x  <minutes 00 to 59 coded in BCD>
; 04h  hours           x  x  <hours 00 to 23 coded in BCD>
; 05h  days            x  x  <days 01 to 31 coded in BCD>
; 06h  weekdays        x  x  x  x  x  <weekdays 0 to 6 in BCD>
; 07h  century_months  C  x  x  <months 01 to 12 coded in BCD>
; 08h  years  <years 00 to 99 coded in BCD>

test_set_rtc_cmd:
        macro_store_symbol2word .rtc_set_date_msg,osCallArg0
        macro_oscall oscPutZArg0

        macro_oscall oscCleanInputBuf
        lda     #80
        sta     osCallArg0
        macro_oscall oscLineEditInput

        ; parse to rtc reading
        ldx     #0              ; index to oscCleanInputBuf
        ldy     #0              ; (read counter 7)
.parse:
        lda     osInputBuffer,x ; upper nybble byte 1
        beq     .parse_error
        jsr     .is_dec
        cmp     #$ff
        beq     .parse_error
        asl
        asl
        asl
        asl
        sta     .rtc_hex_temp

        inx
        lda     osInputBuffer,x ; lower nybble byte 2
        beq     .parse_error
        jsr     .is_dec
        cmp     #$ff
        beq     .parse_error
        ora     .rtc_hex_temp
        sta     .rtc_reading,y

        inx
        cpy     #7
        beq     .skip_final_delim
        lda     osInputBuffer,x ; delim :
        beq     .parse_error
        cmp     #":"
        bne     .parse_error

        inx
        iny
        cpy     #8
        bne     .parse          ;keep going!
        bra     .skip_final_delim

.parse_error:
        txa
        macro_oscall oscPutHexByte
        macro_store_symbol2word .rtc_syntax_error,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return

.skip_final_delim:
        ; process
        lda     .rtc_reading_cc ; century
        cmp     #$19
        bne     .skip_process_cc
        lda     .rtc_reading_mo
        ora     #$80            ; set high bit
        sta     .rtc_reading_mo
.skip_process_cc:
        ;set the clock
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$02,.rtc_reading_ss
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$03,.rtc_reading_mm
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$04,.rtc_reading_hh
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$05,.rtc_reading_dd
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$06,.rtc_reading_dow
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$07,.rtc_reading_mo
        macro_i2c_write_reg_buf RTCID,.rtc_i2c_error,$08,.rtc_reading_yy

        jmp     test_rtc_cmd    ; finish by reading the new time set



; compares A to see if hex. Returns value or $ff if not hex sets carry on error
.is_dec:
        clc
        phx
        ldx     #9
.is_dec_loop:
        cmp     .is_dec_tab,x
        beq     .got_hex
        dex
        bpl     .is_dec_loop
        sec                     ; no so set carry
.got_hex:
        txa                     ; result in A ($ff not found)
        plx
        rts

.is_dec_tab:
        .byte   "0123456789"

.rtc_i2c_error:
        pha
        jsr     os_i2c_stop_cond
        pla
        macro_oscall oscPutHexByte
        macro_store_symbol2word .rtc_err_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

.rtc_set_date_msg:
        .string "set date in form [hh:mm:ss:dd:mm:yy:cc:dow]",CR,LF,"(where cc is century, dow Sunday=0)",CR,LF
.rtc_syntax_error:
        .string "h syntax error",CR,LF
.rtc_err_msg:
        .string " i2c error message writing to RTC",CR,LF
.rtc_hex_temp:
        .byte   0

.rtc_reading:
.rtc_reading_hh:
        .byte   0
.rtc_reading_mm:
        .byte   0
.rtc_reading_ss:
        .byte   0
.rtc_reading_dd:
        .byte   0
.rtc_reading_mo:
        .byte   0
.rtc_reading_yy:
        .byte   0
.rtc_reading_cc:
        .byte   0
.rtc_reading_dow:
        .byte   0,0,0

.rtc_seps:
        .byte   ":: //? "
.dow_tab:
        .byte   "SunMonTueWedThuFriSat"
