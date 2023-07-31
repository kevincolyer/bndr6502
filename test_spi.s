        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"


        .org    userStart       ; expected org
        ; userZp - origin of user zero page
        ; userLowMem - origin of user low mem space ~$600 to userStart

main:
        ; load monitor command to monitor
        macro_store_symbol2word write_byte1_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word write_byte_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word read_byte_cmd,osCallArg0
        macro_oscall oscMonitorAddCmd

        jsr     os_SPI_init
        os_monitor_return

        ; TODO remove when device is merged into os
        ;         .include "deviceSPI.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_byte_cmd:
        .word   write_byte_func_cmd
        .word   write_byte_func
        .word   write_byte_func_help

write_byte_func_cmd:
        .byte   "write",0
write_byte_func_help:
        .byte   "write-write to spi dev device 0",CR,LF,0

write_byte_func:
        jsr     os_SPI_init
        ldy     #0
        lda     #$55
        jsr     os_SPI_Send_Byte

        macro_store_symbol2word write_byte_cmd_msg,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return

write_byte_cmd_msg:
        .byte   "byte sent to device 0",CR,LF,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_byte1_cmd:
        .word   write_byte1_func_cmd
        .word   write_byte1_func
        .word   write_byte1_func_help

write_byte1_func_cmd:
        .byte   "wr",0
write_byte1_func_help:
        .byte   "wr-write and read to spi device 0",CR,LF,0

write_byte1_func:
        lda     #'$'
        macro_oscall oscPutC

        jsr     os_SPI_init
        ldy     #0
        lda     #$55
        jsr     os_SPI_Write_Read_Byte

        macro_oscall oscPutHexByte

        macro_store_symbol2word write_byte1_cmd_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

write_byte1_cmd_msg:
        .byte   ": byte read and byte sent to 0",CR,LF,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
read_byte_cmd:
        .word   read_byte_func_cmd
        .word   read_byte_func
        .word   read_byte_func_help

read_byte_func_cmd:
        .byte   "read",0
read_byte_func_help:
        .byte   "read-read from spi device 0",CR,LF,0

read_byte_func:
        lda     #'$'
        macro_oscall oscPutC
        ldy     #0
        jsr     os_SPI_Recv_Byte

        macro_oscall oscPutHexByte

        macro_store_symbol2word read_byte_cmd_msg,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

read_byte_cmd_msg:
        .byte   ": read from device 0 ",CR,LF,0

