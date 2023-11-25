; from https://github.com/gfoot/sdcard6502/blob/master/src/test_dumpfile.s
; define  DEBUGSD if needed
        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"

buffer=$2000

        .org    userStart       ; expected org

; userZp - origin of user zero page
; userLowMem - origin of user low mem space ~$100 to userStart

main:
        ; load monitor command to monitor
        macro_store_symbol2word sdoldtest,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word sd_test,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_print "Dizzybox initialised",CR,LF

.quit:
        os_monitor_return


sdoldtest:
        .word   sdoldtest_cmd_cmd
        .word   sdoldtest_cmd
        .word   sdoldtest_cmd_help

sdoldtest_cmd_cmd:
        .byte   "sdold",0
sdoldtest_cmd_help:
        .byte   "sdold-test sd card read (old)",CR,LF,0

sdoldtest_msg:
        .byte   "sd test ok",CR,LF,0

sd_test:
        .word   sd_test_cmd_cmd
        .word   sd_test_cmd
        .word   sd_test_cmd_help

sd_test_cmd_cmd:
        .byte   "test",0
sd_test_cmd_help:
        .byte   "test-run test suite",CR,LF,0

mysubdirname:
        .asciiz "SUBFOLDR   "
myfilename:
        .asciiz "DEEPFILETXT"

; helper sub
die_with_os_file_error_and_stage:
        macro_print_c 'S'
        macro_print_c '$'
        lda     stage
        macro_oscall oscPutHexByte
die_with_os_file_error:
        jsr     print_os_file_error
        os_monitor_return

print_os_file_error:
        macro_print_c '$'
        lda     os_file_error
        macro_oscall oscPutHexByte
        macro_putzarg0 msg_os_file_error
        rts

sdoldtest_cmd:
        stz     stage

        macro_putzarg0 msg_initialising


        ; Open root directory
        ; stage 1
        inc     stage
        jsr     os_fat32_open_root_dir
        bcc     .open_root_ok
        jmp     die_with_os_file_error_and_stage
.open_root_ok:

        ; Find subdirectory by name
        ; stage 2
        inc     stage
        ldx     #<mysubdirname
        ldy     #>mysubdirname
        jsr     os_fat32_find_open_dir_ent
        bcc     .foundsubdir

        ; Subdirectory not found

        macro_putzarg0 msg_subd_not_found

        jmp     die_with_os_file_error_and_stage

.foundsubdir:
        macro_oscall oscPutCrLf

;       stage 3
        inc     stage
        ; Find file by name
        ldx     #<myfilename
        ldy     #>myfilename
        jsr     os_fat32_find_open_dir_ent
        bcc     .foundfile

        ; File not found
        macro_putzarg0 msg_file_not_found

        jmp     die_with_os_file_error_and_stage

.foundfile:

        ; Read file contents into buffer
        ;stage 4
        inc     stage
        ldx     #<buffer
        ldy     #>buffer
        jsr     os_fat32_load_file
        ;         bcc     .file_read_ok
        ;         jmp
        ; .file_read_ok:

        ; Dump data to console
        macro_store_symbol2word buffer,osCallArg0

.loopprintfile:
        lda     (osCallArg0)
        beq     .endprintfile
        macro_oscall oscPutC

        inc     osCallArg0
        bne     .loopprintfile
        inc     osCallArg0+1
        bra     .loopprintfile

; ----- part 2
.endprintfile:
        macro_oscall oscPutCrLf
        lda     #$20
        sta     stage

        ;------------------------------------------
        ; list a directory

        jsr     os_fat32_open_root_dir
        ;  jsr     dizzybox_ls
        macro_oscall oscPutCrLf



; ----- part 3
        ;------------------------------------------
        ; try to execute a file
        macro_putzarg0 msg_loadandrun


        jsr     os_fat32_open_root_dir

        ldx     #<exename
        ldy     #>exename
        jsr     os_fat32_find_open_dir_ent
        bcc     .foundfile2

        ; File not found
        macro_putzarg0 msg_file_not_found

        jmp     die_with_os_file_error_and_stage
.foundfile2
        ; t16.PRG is assembled to $2000 with PRG header.
        ;         ldx     #<buffer
        ;         ldy     #>buffer
        ;         jsr     os_fat32_load_file

        jsr     os_executable_load
        bcc     .execute
        lda     os_file_error   ; was the error eof?
        beq     .execute        ; yes
        jmp     die_with_os_file_error_and_stage
.execute
        lda     osCallArg0+1
        macro_oscall oscPutHexByte
        lda     osCallArg0
        macro_oscall oscPutHexByte
        ldx     #0
.printloop:
        lda     msg_file_loaded,x
        beq     .run
        phx
        macro_oscall oscPutC
        plx
        inx
        bne     .printloop
.run:
        jmp     (osCallArg0)


msg_file_loaded:
        .string ": loaded file ok",CR,LF
exename:
        .string "T16     PRG"

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

msg_os_file_error:
        .string ": os file error",CR,LF

msg_subd_not_found:
        .string " subdirectory not found",CR,LF

msg_dirlisting:
        .string "Listing Directory",CR,LF

msg_loadandrun:
        .string "Loading and running a program from SD card",CR,LF






; ===================================================
sd_test_cmd:
;         jsr     dizzybox_init
;         macro_putzarg0 .msg_test
;         macro_putzarg0 .msg_test_p_and_f
;         ldx     #0
; .testloop:
;         ldy     #0
;         macro_oscall oscGetC
;         bcc     .no_key
;         bra     .early_quit
; .no_key:
;         lda     .p_and_f_test,x
;         bpl     .not_done_testing; $ff marks end of strings
; .early_quit:
;         jmp     .done_testing
;         ;
; .not_done_testing:
;         sta     osOutputBuffer,y
;         beq     .done_copy      ; if z terminated done
;         iny
;         inx
;         bne     .no_key
; .done_copy:
;         inx
;         macro_print_c "'"
;         macro_putzarg0 osOutputBuffer
;         macro_putzarg0 .arrow
;         stz     os_file_error
;         macro_store_symbol2word osOutputBuffer,osCallArg0
;         phx
;         jsr     _parse_and_format_8_3
;         plx
;         macro_putzarg0 filename
;         macro_print_c "'"
;
;         lda     os_file_error   ; E_OK?
;         beq     .pass           ; yes
;         ; fail message
;         macro_print_c SPACE
;         lda     os_file_error
;         macro_oscall oscPutHexByte
;         macro_putzarg0 .msg_fail
;         jmp     .testloop
;         ; passing means we can give a roundtrip test too
; .pass:
;         macro_putzarg0 .msg_pass
; .next_loop:
;         macro_store_symbol2word filename,osCallArg1
;         macro_store_symbol2word osOutputBuffer,osCallArg0
;         jsr     _format_8_dot_3 ; test  roundtrip
;         macro_print_c "'"
;         macro_putzarg0 osOutputBuffer
;         macro_print_c "'"
;         macro_oscall oscPutCrLf
;         jmp     .testloop

.done_testing:
        jsr     more_testing
        os_monitor_return

.msg_test:
        .string "running test "
.msg_test_p_and_f:
        .string "_parse_and_format_8_3",CR,LF
.msg_test_pwd:
        .string "dizzybox_pwd",CR,LF
.msg_test_cd:
        .string "dizzybox_cd",CR,LF
.arrow:
        .string "' => '"
.msg_fail:
        .string " FAIL",CR,LF
.msg_pass:
        .string " PASS "

.p_and_f_test:
        ; test parse and _parse_and_format_8_3
        .string "1"
        .string "1.123"
        .string "1.12"
        .string "12345678"
        .string "12345678.123"
        .string "."
        .string "123456789"
        .string "1234 567.TXT"
        .string "fail.txt"
        .string "fail?*.txt"
        .string "1.1234"
        .string "12345678.1234"
        .byte   $ff

more_testing:
;         macro_putzarg0 .msg_testing_cd
;         lda     #$ff
;         sta     os_in_testing_mode; needed for testing of cd routine  TODO - check I may move opening dirs to iterate path...
;         ldx     #0
; .testloop:
;         lda     .cd_tests,x
;         bpl     .not_done
;         jmp     .done
; .not_done:
;         macro_putzarg0 .msg_test
;
;         ldy     #0
;         ; load test
; .loop2:
;         lda     .cd_tests,x
;         sta     osOutputBuffer,y
;         beq     .start_test
;         inx
;         iny
;         bne     .loop2
;
; .start_test:
;         sta     osOutputBuffer,y; final terminating zero
;
;         macro_putzarg0 osOutputBuffer
;         macro_putzarg0 .msg_test_arrow
;
;         macro_store_symbol2word osOutputBuffer,osCallArg0
;         jsr     dizzybox_cd
;
;         bcc     .cont           ; error?
;         lda     os_file_error
;         beq     .cont           ; no error really. TODO why was carry set?
;         lda     #'$'
;         macro_oscall oscPutC
;         lda     os_file_error
;         macro_oscall oscPutHexByte
;         lda     #SPACE
;         macro_oscall oscPutC
; .cont:
;         jsr     dizzybox_pwd
;
;         inx
;         iny
;         jmp     .testloop       ; no!
; .done:
;         stz     os_in_testing_mode
;         macro_oscall oscPutCrLf
        rts
.cd_tests:
        .string "."
        .string ".."
        .string "/"
        .string "123"
        .string "/"
        .string "12345678.123"
        .string ".."
        .string "123"
        .string "456"
        .string "789"
        .string ".."
        .string "1234.12"
        .string ""              ; nothing = go to home
        .byte   $ff
.msg_testing_cd:
        .string "Testing cd command:",CR,LF
.msg_test:
        .string "cd "
.msg_test_arrow:
        .string " => "

stage:
        .byt


