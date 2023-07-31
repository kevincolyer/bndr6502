;===============================================
;       constants for 6502bndr development
;===============================================


CLOCKSPEED      = 1843200       ; 1.8432Mhz
TIMER1TIMEOUT   = 18430         ; (0.01*CLOCKSPEED)-2 T1 period = n+2 / φ2 freq
WARMBOOTSET     = 1

; XMODEM Control Character Constants
SOH             = $01           ; start block
EOT             = $04           ; end of text marker
ACK             = $06           ; good block acknowledged
NAK             = $15           ; bad block acknowledged
CAN             = $18           ; cancel (not standard, not supported)
        ; ASCII defines
CR              = $0d           ; carriage return
LF              = $0a           ; line feed
NL              = LF
ESC             = $1b           ; ESC to exit
SPACE           = $20
BS              = $08
DEL             = $7F
ETX             = $03           ; = CTRL-C usually
CTRL_C          = ETX


; i2c constants
; NACK is high (1) ACK is low (0)
i2c_F_SEND_ACK=0
i2c_F_SEND_NACK=1
i2c_F_SEND_START=2
i2c_F_SEND_STOP=4

; ; SDA [7] and SCL [0]
; ; a 1 = LOW, 1 means OUTPUT, and PORT is set to LOW
; ; a 0 = HIGH, 0 means INPUT => High-Z w/pull-up
; i2c_SDA_pin=%10000000
; i2c_SCL_pin=%00000001
;
;
; i2c_pins_read=0
; i2c_pins_write=(i2c_SDA_pin|i2c_SCL_pin)

; moved to os_constants
E_i2c_OK=0
E_i2c_TIMEOUT=1
E_i2c_NACK=2
E_i2c_READBYTE=3
E_i2c_WRITEBTE=4
E_i2c_ARBITRATIONLOST=5

; see os_monitor.inc for print text versions of these constants
E_OK=0  ;
E_ERROR=1                       ;
E_SD_NOT_FOUND=2
E_DIR_NOT_FOUND=3
E_FILE_NOT_FOUND=4
E_FS_READ_ERROR=5
E_FS_WRITE_ERROR=6
E_EOF=7
E_NAME_TOO_LONG=8
E_FAT32_INIT_ERROR=9
E_INVALID_FILENAME_CHAR=10
E_OPEN_DIR_FAIL=11
E_FILE_HEADER=12
E_BAD_FILENAME=13
E_OPERATION_INTERRUPTED=14
E_SYNTAX_ERROR=15
