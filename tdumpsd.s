; from https://github.com/gfoot/sdcard6502/blob/master/src/test_dumpfile.s
; define  DEBUGSD if needed
        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"

buffer=$2000

        .org    userStart       ; expected org

; userZp - origin of user zero page
; userLowMem - origin of user low mem space ~$600 to userStart

main:
        ; load monitor command to monitor
        macro_store_symbol2word testcmd,osCallArg0
        macro_oscall oscMonitorAddCmd

        os_monitor_return

testcmd:
        .word   miscfunction_cmd
        .word   miscfunction
        .word   miscfunction_help

miscfunction_cmd:
        .byte   "sd",0
miscfunction_help:
        .byte   "sd-test sd card read",CR,LF,0


testcmd_msg:
        .byte   "sd function works well",CR,LF,0

;         .include "device_spi.inc"
;        .include "libsd.inc"
        .include "libfat32.inc"

mysubdirname:
        .asciiz "SUBFOLDR   "
myfilename:
        .asciiz "DEEPFILETXT"

miscfunction:
        macro_store_symbol2word msg_initialising,osCallArg0
        macro_oscall oscPutZArg0

        ; Initialise
        macro_store_symbol2word msg_initialising_spi,osCallArg0
        macro_oscall oscPutZArg0

;       done in kernal now
;         ; set up via for SPI contol
;         jsr     SPI_init
;         macro_store_symbol2word msg_ok,osCallArg0
;         macro_oscall oscPutZArg0

        ; set up sd card on device 0
        macro_store_symbol2word msg_initialising_sd,osCallArg0
        macro_oscall oscPutZArg0
        jsr     os_sd_init
        bcc     .sd_ok
        macro_store_symbol2word msg_not_ok,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return

.sd_ok:
        macro_store_symbol2word msg_ok,osCallArg0
        macro_oscall oscPutZArg0

        ; set up fat32
        macro_store_symbol2word msg_initialising_fat32,osCallArg0
        macro_oscall oscPutZArg0
        jsr     fat32_init
        bcc     .initsuccess

        ; Error during FAT32 initialization
        .ifdef  DEBUGSD
        pha
        lda     #'Z'
        macro_oscall oscPutC
        lda     fat32_errorstage
        macro_oscall oscPutHexByte
        lda     #':'
        macro_oscall oscPutC
        pla
        macro_oscall oscPutHexByte
        macro_oscall oscPutCrLf
        .endif

        macro_store_symbol2word msg_fat32_init_error,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

.initsuccess:
        .ifdef  DEBUGSD
        stz     osR2
        .endif

        macro_store_symbol2word msg_ok,osCallArg0
        macro_oscall oscPutZArg0
        ; Open root directory
        ; stage 0
        jsr     fat32_openroot

        .ifdef  DEBUGSD
        lda     osR2
        macro_oscall oscPutHexByte
        .endif

        ; stage 1
        ; Find subdirectory by name
        ldx     #<mysubdirname
        ldy     #>mysubdirname
        jsr     fat32_finddirent
        bcc     .foundsubdir

        ; Subdirectory not found
        macro_store_symbol2word msg_subd_not_found,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

.foundsubdir:
        .ifdef  DEBUGSD
        inc     osR2
        lda     osR2
        macro_oscall oscPutHexByte
        .endif

        ; stage 2
        ; Open subdirectory
        jsr     fat32_opendirent

        .ifdef  DEBUGSD
        inc     osR2
        lda     osR2
        macro_oscall oscPutHexByte
        .endif

        ; Find file by name
        ldx     #<myfilename
        ldy     #>myfilename
        jsr     fat32_finddirent
        bcc     .foundfile

        ; File not found
        macro_store_symbol2word msg_file_not_found,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return

.foundfile:
        .ifdef  DEBUGSD
        inc     osR2
        lda     osR2
        macro_oscall oscPutHexByte
        .endif

        ;stage 3
        ; Open file
        jsr     fat32_opendirent

        .ifdef  DEBUGSD
        inc     osR2
        lda     osR2
        macro_oscall oscPutHexByte
        .endif

        ;stage 4
        ; Read file contents into buffer
        lda     #<buffer
        sta     fat32_address
        lda     #>buffer
        sta     fat32_address+1

        jsr     fat32_file_read


        .ifdef  DEBUGSD
        inc     osR2
        lda     osR2
        macro_oscall oscPutHexByte
        macro_oscall oscPutCrLf
        .endif
        ; Dump data to console
        macro_store_symbol2word buffer,osCallArg0

.loopprintfile:
        lda     (osCallArg0)
        beq     .listadir
        macro_oscall oscPutC

        inc     osCallArg0
        bne     .loopprintfile
        inc     osCallArg0+1
        bra     .loopprintfile

.listadir:
        macro_oscall oscPutCrLf

        ;------------------------------------------
        ; list a directory
        jsr     dir_listing
        macro_oscall oscPutCrLf



        ;------------------------------------------
        ; try to execute a file
        macro_store_symbol2word msg_loadandrun,osCallArg0
        macro_oscall oscPutZArg0


        jsr     fat32_openroot

        ldx     #<exename
        ldy     #>exename
        jsr     fat32_finddirent
        bcc     .foundfile2

        ; File not found
        macro_store_symbol2word msg_file_not_found,osCallArg0
        macro_oscall oscPutZArg0

        os_monitor_return
.foundfile2
        jsr     fat32_opendirent
        ; t16.exe is hard coded to be loaded to $2000 - it is just a binary file - no header.
        lda     #<buffer
        sta     fat32_address
        lda     #>buffer
        sta     fat32_address+1

        jsr     fat32_file_read

        jmp     buffer

        os_monitor_return
exename:
        .string "T16     EXE"

msg_initialising:
        .string "Initialising ",CR,LF


msg_ok:
        .string " OK",CR,LF
msg_not_ok:
        .string " FAIL",CR,LF

msg_initialising_spi:
        .string " spi bus:"

msg_initialising_sd:
        .string " sd card to spi mode:"

msg_initialising_fat32:
        .string " fat32 init:"

msg_fat32_init_error:
        .string " fat32 init error",CR,LF

msg_file_not_found:
        .string " file not found",CR,LF

msg_subd_not_found:
        .string " subdirectory not found",CR,LF

msg_dirlisting:
        .string "Listing Root Directory",CR,LF

msg_loadandrun:
        .string "Loading and running a program from SD card",CR,LF


dir_listing:
        macro_store_symbol2word msg_dirlisting,osCallArg0
        macro_oscall oscPutZArg0

        jsr     fat32_openroot
.printloop:
        jsr     fat32_readdirent
        bcs     .quit
        macro_oscall oscPutHexByte
        lda     #SPACE
        macro_oscall oscPutC
        ldy     #0
.printname:
        lda     (zp_sd_address),y
        macro_oscall oscPutC
        iny
        cpy     #8
        bne     .printname
        lda     #'.'
        macro_oscall oscPutC
        ldy     #0
.printext:
        lda     (zp_sd_address),y
        macro_oscall oscPutC
        iny
        cpy     #3
        bne     .printext
        macro_oscall oscPutCrLf
        bra     .printloop

.quit:
        rts

; HEADER IDEAS for BNDR exe files
; magic         .byte "BNDR"
; version       .byte 1
; type          .byte "r" or "f" for relocateable or fixed
; compiledaddres .word org
; loadaddress   .word load (or blank)
; zpneeded      .byte 0-127
; relocated     .byte 0 or "y" once relocated
; length        .word
; main          .word address of main func

